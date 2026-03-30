/*
export.ts (standalone script from website's firebase ones)

Retrieves the firestore data via Firebase admin SDK
*/

import { initializeApp, cert } from "firebase-admin/app";
import { getFirestore, Timestamp } from "firebase-admin/firestore";
import * as fs from "node:fs";
import serviceAccount from "./serviceAccountKey.json";

initializeApp({
    credential: cert(serviceAccount as any),
    databaseURL: "https://feedback-experiment-mie286-default-rtdb.firebaseio.com"
});
const db = getFirestore();

// Follow the same trial format as db.ts + participantName now that it's part of the data
type TrialData = {
    participantName: string;
    participantNumber: number;
    feedbackType: "POSITIVE" | "NEGATIVE";
    numberCorrect: number;
    numberIncorrect: number;
    totalClicks: number;
    totalElapsedTime: number;
    thinkingTime: number;
}

type TrialRecord = TrialData & {
    id: string,
    createdAt?: Timestamp;
};  

function escapeCSV(value: unknown): string {
    if (value === null || value === undefined) return "";
    const str = String(value);
    if (/[",\n]/.test(str)) {
        return `"${str.replace(/"/g, '""')}"`;
    }
    return str;
}

function toCSV(rows: TrialRecord[]): string {
    const columns: (keyof Omit<TrialRecord, "createdAt"> | "createdAt")[] = [
        "id",
        "participantName",
        "participantNumber",
        "feedbackType",
        "numberCorrect",
        "numberIncorrect",
        "totalClicks",
        "totalElapsedTime",
        "thinkingTime",
        "createdAt"
    ];

    // construct csv lines, separated by commas
    const lines = [
        columns.join(","),
        ...rows.map((row) => 
            columns.map((col) => {
                if (col === "createdAt") {
                    return escapeCSV(row.createdAt?.toDate().toISOString() ?? "");
                } else {
                    return escapeCSV(row[col]);
                }
            }).join(",")
        ),
    ];

    // new lines
    return lines.join("\n");
}

async function exportTrialsToCsv(): Promise<void> {
    const snapshot = await db.collection("trials").get();

    const rows: TrialRecord[] = snapshot.docs.map((doc) => {
        const data = doc.data();

        return {
            id: doc.id,
            participantName: data.participantName,
            participantNumber: data.participantNumber,
            feedbackType: data.feedbackType,
            numberCorrect: data.numberCorrect,
            numberIncorrect: data.numberIncorrect,
            totalClicks: data.totalClicks,
            totalElapsedTime: data.totalElapsedTime,
            thinkingTime: data.thinkingTime,
            createdAt: data.createdAt,
        };
    });

    const csv = toCSV(rows);
    fs.writeFileSync("analysis/data/trials.csv", csv, "utf8");
    console.log("exported trials.csv");
}

exportTrialsToCsv().catch(console.error);
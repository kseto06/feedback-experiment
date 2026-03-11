import { collection, addDoc, serverTimestamp } from "firebase/firestore";
import { query, orderBy, limit, getDocs, Timestamp } from "firebase/firestore";
import { db } from "./firebase";

export interface TrialData {
    name: string;
    participantNumber: number;
    feedbackType: "POSITIVE" | "NEGATIVE";
    numberCorrect: number;
    numberIncorrect: number;
    totalClicks: number;
    totalElapsedTime: number;
    thinkingTime: number;
}

export interface TrialRecord extends TrialData {
    id: string;
    createdAt?: Timestamp;
}

export async function saveFeedback(trial: TrialData): Promise<void> {
    await addDoc(collection(db, "trials"), {
        ...trial,
        createdAt: serverTimestamp(),
    });
}

export async function retrieveLastTrial(): Promise<TrialRecord | null> {
    /*
    Retrieve the last trial for checking whether or not to give positive/negative feedback
    */
    const q = query(
        collection(db, "trials"),
        orderBy("createdAt", "desc"),
        limit(1) 
    )

    const snapshot = await getDocs(q);

    if (snapshot.empty) 
        return null;

    const doc = snapshot.docs[0];
    const data = doc.data() as TrialData & { createdAt?: Timestamp };

    return {
        id: doc.id,
        ...data
    }
}
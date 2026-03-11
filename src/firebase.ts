import { initializeApp } from "firebase/app";
import { getFirestore } from "firebase/firestore";

const firebaseConfig = {
  apiKey: "AIzaSyACV4NiDVI4ridBV9853GGTh4GqCmeAHro",
  authDomain: "feedback-experiment-mie286.firebaseapp.com",
  projectId: "feedback-experiment-mie286",
  storageBucket: "feedback-experiment-mie286.firebasestorage.app",
  messagingSenderId: "21144107596",
  appId: "1:21144107596:web:bc0ebe0ff550db127ad2e9",
  measurementId: "G-E6X0ZLRWM4"
};

const app = initializeApp(firebaseConfig);
export const db = getFirestore(app);
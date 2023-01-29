// Import the functions you need from the SDKs you need
import { initializeApp } from 'firebase/app';
import { getAuth } from 'firebase/auth';
import { getFirestore } from 'firebase/firestore';
// https://firebase.google.com/docs/web/setup#available-libraries

// Your web app's Firebase configuration
// For Firebase JS SDK v7.20.0 and later, measurementId is optional
const firebaseConfig = {
  apiKey: 'AIzaSyDw4Wb3pAswoflIpz69oker-U6cMes-za0',
  authDomain: 'pwc-9ds.firebaseapp.com',
  projectId: 'pwc-9ds',
  storageBucket: 'pwc-9ds.appspot.com',
  messagingSenderId: '174807098074',
  appId: '1:174807098074:web:661a3552af18693bb8bbe3',
  measurementId: 'G-YDGMYVN7YV',
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);

const auth = getAuth(app);
const db = getFirestore(app);

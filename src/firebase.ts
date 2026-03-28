import { initializeApp } from 'firebase/app';
import { getAuth } from 'firebase/auth';
import { getFirestore, doc, getDocFromServer } from 'firebase/firestore';
import firebaseConfig from './firebase-applet-config.json';

// Initialize Firebase SDK with the provided configuration
const app = initializeApp(firebaseConfig);

// Initialize Firestore with the specific database ID from the config
export const db = getFirestore(app, firebaseConfig.firestoreDatabaseId);

// Initialize Firebase Authentication
export const auth = getAuth();

/**
 * Operation types for Firestore error tracking
 */
export enum OperationType {
  CREATE = 'create',
  UPDATE = 'update',
  DELETE = 'delete',
  LIST = 'list',
  GET = 'get',
  WRITE = 'write',
}

/**
 * Interface for detailed Firestore error information
 */
export interface FirestoreErrorInfo {
  error: string;
  operationType: OperationType;
  path: string | null;
  authInfo: {
    userId: string | undefined;
    email: string | null | undefined;
    emailVerified: boolean | undefined;
    isAnonymous: boolean | undefined;
    tenantId: string | null | undefined;
    providerInfo: {
      providerId: string;
      displayName: string | null;
      email: string | null;
      photoUrl: string | null;
    }[];
  }
}

/**
 * Handles Firestore errors by logging detailed information and throwing a JSON-formatted error
 * @param error The error object
 * @param operationType The type of Firestore operation that failed
 * @param path The Firestore path involved in the operation
 */
export function handleFirestoreError(error: unknown, operationType: OperationType, path: string | null) {
  const errInfo: FirestoreErrorInfo = {
    error: error instanceof Error ? error.message : String(error),
    authInfo: {
      userId: auth.currentUser?.uid,
      email: auth.currentUser?.email,
      emailVerified: auth.currentUser?.emailVerified,
      isAnonymous: auth.currentUser?.isAnonymous,
      tenantId: auth.currentUser?.tenantId,
      providerInfo: auth.currentUser?.providerData.map(provider => ({
        providerId: provider.providerId,
        displayName: provider.displayName,
        email: provider.email,
        photoUrl: provider.photoURL
      })) || []
    },
    operationType,
    path
  }
  
  // Use a safe way to log and throw errors to avoid circular structure issues
  const errorString = `Firestore Error [${operationType}] at ${path || 'unknown'}: ${errInfo.error}`;
  console.error(errorString, errInfo);
  
  try {
    throw new Error(JSON.stringify(errInfo));
  } catch (e) {
    // If JSON.stringify fails due to circular structure or other reasons, throw a simpler error
    throw new Error(errorString);
  }
}

/**
 * Validates the connection to Firestore on initialization
 */
async function testConnection() {
  try {
    // Attempt to fetch a test document to verify connectivity
    await getDocFromServer(doc(db, 'test', 'connection'));
  } catch (error) {
    // Log a helpful message if the client appears to be offline
    if(error instanceof Error && error.message.includes('the client is offline')) {
      console.error("Please check your Firebase configuration. Ensure you are online and the Firestore database is accessible.");
    }
  }
}

// Execute the connection test
testConnection();

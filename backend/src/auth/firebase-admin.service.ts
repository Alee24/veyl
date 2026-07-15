import { Injectable, OnModuleInit, Logger } from '@nestjs/common';
import {
  initializeApp,
  getApps,
  cert,
  applicationDefault,
  App,
} from 'firebase-admin/app';
import { getAuth, DecodedIdToken } from 'firebase-admin/auth';

@Injectable()
export class FirebaseAdminService implements OnModuleInit {
  private readonly logger = new Logger(FirebaseAdminService.name);
  private app: App;

  onModuleInit() {
    // Singleton guard – only initialize once
    if (getApps().length > 0) {
      this.app = getApps()[0];
      this.logger.log('Firebase Admin reusing existing app.');
      return;
    }

    try {
      const serviceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;

      if (serviceAccountJson) {
        const serviceAccount = JSON.parse(serviceAccountJson);
        this.app = initializeApp({
          credential: cert(serviceAccount),
        });
        this.logger.log('Firebase Admin initialized with service account.');
      } else {
        // Fall back to Application Default Credentials (GCP / Cloud Run)
        this.app = initializeApp({
          credential: applicationDefault(),
          projectId: process.env.FIREBASE_PROJECT_ID || 'veyl-1b1e8',
        });
        this.logger.log(
          'Firebase Admin initialized with application default credentials.',
        );
      }
    } catch (error) {
      this.logger.error('Firebase Admin initialization failed:', error);
    }
  }

  /**
   * Verify a Firebase ID token and return the decoded token.
   * Throws if the token is invalid.
   */
  async verifyIdToken(idToken: string): Promise<DecodedIdToken> {
    return getAuth(this.app).verifyIdToken(idToken);
  }
}

import { Injectable, OnModuleInit, Logger } from '@nestjs/common';
import {
  initializeApp,
  getApps,
  cert,
  applicationDefault,
  App,
} from 'firebase-admin/app';
import { getAuth, DecodedIdToken } from 'firebase-admin/auth';
import { readFileSync } from 'fs';
import { resolve } from 'path';

@Injectable()
export class FirebaseAdminService implements OnModuleInit {
  private readonly logger = new Logger(FirebaseAdminService.name);
  private app: App;

  onModuleInit() {
    // Singleton guard — only initialize once across hot reloads
    if (getApps().length > 0) {
      this.app = getApps()[0];
      this.logger.log('Firebase Admin reusing existing app.');
      return;
    }

    try {
      // Priority 1: file path (local dev / Docker volume mount)
      const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH;
      if (serviceAccountPath) {
        const absolutePath = resolve(process.cwd(), serviceAccountPath);
        const serviceAccount = JSON.parse(readFileSync(absolutePath, 'utf-8'));
        this.app = initializeApp({ credential: cert(serviceAccount) });
        this.logger.log(
          `Firebase Admin initialized from file: ${absolutePath}`,
        );
        return;
      }

      // Priority 2: inline JSON in env var (CI / production secrets manager)
      const serviceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
      if (serviceAccountJson) {
        const serviceAccount = JSON.parse(serviceAccountJson);
        this.app = initializeApp({ credential: cert(serviceAccount) });
        this.logger.log('Firebase Admin initialized from JSON env var.');
        return;
      }

      // Priority 3: Application Default Credentials (GCP / Cloud Run)
      this.app = initializeApp({
        credential: applicationDefault(),
        projectId: process.env.FIREBASE_PROJECT_ID || 'veyl-1b1e8',
      });
      this.logger.log(
        'Firebase Admin initialized with application default credentials.',
      );
    } catch (error) {
      this.logger.error('Firebase Admin initialization failed:', error);
    }
  }

  /**
   * Verify a Firebase ID token and return the decoded token.
   * Throws FirebaseAuthError if the token is invalid or expired.
   */
  async verifyIdToken(idToken: string): Promise<DecodedIdToken> {
    return getAuth(this.app).verifyIdToken(idToken);
  }
}

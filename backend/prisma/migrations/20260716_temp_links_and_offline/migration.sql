-- CreateTable
CREATE TABLE "TemporaryLink" (
    "id" TEXT NOT NULL,
    "ownerId" TEXT NOT NULL,
    "secureToken" TEXT NOT NULL,
    "name" TEXT,
    "expiresAt" TIMESTAMP(3),
    "maxScans" INTEGER,
    "currentScans" INTEGER NOT NULL DEFAULT 0,
    "allowedActions" TEXT[],
    "requireApproval" BOOLEAN NOT NULL DEFAULT false,
    "password" TEXT,
    "status" TEXT NOT NULL DEFAULT 'ACTIVE',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "TemporaryLink_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "OfflineQueue" (
    "id" TEXT NOT NULL,
    "sender" TEXT NOT NULL,
    "receiver" TEXT NOT NULL,
    "message" TEXT NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'PENDING',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "syncedAt" TIMESTAMP(3),

    CONSTRAINT "OfflineQueue_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "TemporaryLink_secureToken_key" ON "TemporaryLink"("secureToken");

-- AddForeignKey
ALTER TABLE "TemporaryLink" ADD CONSTRAINT "TemporaryLink_ownerId_fkey" FOREIGN KEY ("ownerId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

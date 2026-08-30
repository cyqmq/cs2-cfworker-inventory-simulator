-- CreateTable
CREATE TABLE "User" (
    "avatar" TEXT NOT NULL,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "id" TEXT NOT NULL PRIMARY KEY,
    "inventory" TEXT,
    "lastSeen" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "name" TEXT NOT NULL,
    "syncedAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL
);

-- CreateTable
CREATE TABLE "EconomyItem" (
    "altName" TEXT,
    "base" BOOLEAN NOT NULL,
    "baseItemId" INTEGER,
    "category" TEXT,
    "collection" TEXT,
    "def" INTEGER,
    "free" BOOLEAN NOT NULL,
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "model" TEXT,
    "name" TEXT NOT NULL,
    "rarity" TEXT,
    "type" TEXT NOT NULL
);

-- CreateTable
CREATE TABLE "EconomyPrice" (
    "currency" TEXT NOT NULL DEFAULT 'USD',
    "economyItemId" INTEGER NOT NULL,
    "exterior" TEXT,
    "last24h" DECIMAL,
    "last7d" DECIMAL,
    "last30d" DECIMAL,
    "last90d" DECIMAL,
    "marketHashName" TEXT NOT NULL,
    "sourceDate" DATETIME NOT NULL,
    "souvenir" BOOLEAN NOT NULL DEFAULT false,
    "statTrak" BOOLEAN NOT NULL DEFAULT false,

    PRIMARY KEY ("sourceDate", "marketHashName"),
    CONSTRAINT "EconomyPrice_economyItemId_fkey" FOREIGN KEY ("economyItemId") REFERENCES "EconomyItem" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "EconomyPriceMeta" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT DEFAULT 1,
    "lastAttemptedAt" DATETIME,
    "lastAttemptedSourceDate" DATETIME,
    "lastFailureAt" DATETIME,
    "lastFailureMessage" TEXT,
    "lastSucceededAt" DATETIME,
    "lastSucceededSourceDate" DATETIME,
    "lastUnmatchedCount" INTEGER,
    "lastUnmatchedNames" TEXT,
    "updatedAt" DATETIME NOT NULL
);

-- CreateTable
CREATE TABLE "UserInventoryItem" (
    "charges" INTEGER,
    "containerUid" INTEGER,
    "equipped" BOOLEAN NOT NULL DEFAULT false,
    "equippedCT" BOOLEAN NOT NULL DEFAULT false,
    "equippedT" BOOLEAN NOT NULL DEFAULT false,
    "id" TEXT NOT NULL PRIMARY KEY,
    "inventoryKey" TEXT NOT NULL,
    "itemId" INTEGER NOT NULL,
    "itemUpdatedAt" DATETIME,
    "nameTag" TEXT,
    "seed" INTEGER,
    "sourceContainerId" INTEGER,
    "statTrak" INTEGER,
    "uid" INTEGER NOT NULL,
    "userId" TEXT NOT NULL,
    "wear" REAL,
    CONSTRAINT "UserInventoryItem_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "UserInventoryItemSticker" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "itemId" INTEGER NOT NULL,
    "rotation" REAL,
    "schema" INTEGER,
    "slot" INTEGER NOT NULL,
    "userInventoryItemId" TEXT NOT NULL,
    "wear" REAL,
    "x" REAL,
    "y" REAL,
    CONSTRAINT "UserInventoryItemSticker_userInventoryItemId_fkey" FOREIGN KEY ("userInventoryItemId") REFERENCES "UserInventoryItem" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "UserInventoryItemPatch" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "itemId" INTEGER NOT NULL,
    "slot" INTEGER NOT NULL,
    "userInventoryItemId" TEXT NOT NULL,
    CONSTRAINT "UserInventoryItemPatch_userInventoryItemId_fkey" FOREIGN KEY ("userInventoryItemId") REFERENCES "UserInventoryItem" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "UserInventoryItemKeychain" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "itemId" INTEGER NOT NULL,
    "seed" INTEGER,
    "slot" INTEGER NOT NULL,
    "userInventoryItemId" TEXT NOT NULL,
    "x" REAL,
    "y" REAL,
    "z" REAL,
    CONSTRAINT "UserInventoryItemKeychain_userInventoryItemId_fkey" FOREIGN KEY ("userInventoryItemId") REFERENCES "UserInventoryItem" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "UserInventoryProjection" (
    "failedSyncedAt" DATETIME,
    "projectedAt" DATETIME,
    "projectedSyncedAt" DATETIME,
    "updatedAt" DATETIME NOT NULL,
    "userId" TEXT NOT NULL PRIMARY KEY,
    CONSTRAINT "UserInventoryProjection_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "InventoryProjectionMeta" (
    "backfillCompletedAt" DATETIME,
    "backfillCursor" TEXT,
    "cs2LibVersion" TEXT,
    "economyProjectionVersion" INTEGER NOT NULL DEFAULT 1,
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT DEFAULT 1,
    "updatedAt" DATETIME NOT NULL
);

-- CreateTable
CREATE TABLE "InventoryRecovery" (
    "changes" TEXT,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "id" TEXT NOT NULL PRIMARY KEY,
    "inventory" TEXT NOT NULL,
    "reason" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    CONSTRAINT "InventoryRecovery_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "UserCache" (
    "args" TEXT,
    "body" TEXT NOT NULL,
    "timestamp" DATETIME NOT NULL,
    "url" TEXT NOT NULL,
    "userId" TEXT NOT NULL,

    PRIMARY KEY ("url", "userId"),
    CONSTRAINT "UserCache_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "UserPreference" (
    "background" TEXT,
    "hideFilters" TEXT,
    "hideFreeItems" TEXT,
    "hideNewItemLabel" TEXT,
    "language" TEXT,
    "prefer2dStickerEditor" TEXT,
    "statsForNerds" TEXT,
    "userId" TEXT NOT NULL PRIMARY KEY,
    CONSTRAINT "UserPreference_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "ApiCredential" (
    "apiKey" TEXT NOT NULL PRIMARY KEY,
    "comment" TEXT,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "scope" TEXT,
    "updatedAt" DATETIME NOT NULL
);

-- CreateTable
CREATE TABLE "ApiAuthToken" (
    "apiKey" TEXT NOT NULL,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "token" TEXT NOT NULL PRIMARY KEY,
    "userId" TEXT NOT NULL,
    CONSTRAINT "ApiAuthToken_apiKey_fkey" FOREIGN KEY ("apiKey") REFERENCES "ApiCredential" ("apiKey") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "ApiAuthToken_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "Rule" (
    "name" TEXT NOT NULL PRIMARY KEY,
    "type" TEXT NOT NULL DEFAULT 'string',
    "value" TEXT NOT NULL
);

-- CreateTable
CREATE TABLE "UserRule" (
    "name" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "value" TEXT NOT NULL,

    PRIMARY KEY ("name", "userId"),
    CONSTRAINT "UserRule_name_fkey" FOREIGN KEY ("name") REFERENCES "Rule" ("name") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "UserRule_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "Group" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "priority" INTEGER NOT NULL DEFAULT 0
);

-- CreateTable
CREATE TABLE "UserGroup" (
    "groupId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,

    PRIMARY KEY ("groupId", "userId"),
    CONSTRAINT "UserGroup_groupId_fkey" FOREIGN KEY ("groupId") REFERENCES "Group" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "UserGroup_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "GroupRule" (
    "groupId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "value" TEXT NOT NULL,

    PRIMARY KEY ("groupId", "name"),
    CONSTRAINT "GroupRule_groupId_fkey" FOREIGN KEY ("groupId") REFERENCES "Group" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "GroupRule_name_fkey" FOREIGN KEY ("name") REFERENCES "Rule" ("name") ON DELETE CASCADE ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "RateLimitBucket" (
    "key" TEXT NOT NULL PRIMARY KEY,
    "tokens" REAL NOT NULL,
    "updatedAt" DATETIME NOT NULL
);

-- CreateIndex
CREATE INDEX "User_syncedAt_idx" ON "User"("syncedAt");

-- CreateIndex
CREATE INDEX "EconomyPrice_economyItemId_sourceDate_idx" ON "EconomyPrice"("economyItemId", "sourceDate");

-- CreateIndex
CREATE INDEX "UserInventoryItem_itemId_idx" ON "UserInventoryItem"("itemId");

-- CreateIndex
CREATE UNIQUE INDEX "UserInventoryItem_userId_inventoryKey_key" ON "UserInventoryItem"("userId", "inventoryKey");

-- CreateIndex
CREATE INDEX "UserInventoryItemSticker_itemId_idx" ON "UserInventoryItemSticker"("itemId");

-- CreateIndex
CREATE UNIQUE INDEX "UserInventoryItemSticker_userInventoryItemId_slot_key" ON "UserInventoryItemSticker"("userInventoryItemId", "slot");

-- CreateIndex
CREATE INDEX "UserInventoryItemPatch_itemId_idx" ON "UserInventoryItemPatch"("itemId");

-- CreateIndex
CREATE UNIQUE INDEX "UserInventoryItemPatch_userInventoryItemId_slot_key" ON "UserInventoryItemPatch"("userInventoryItemId", "slot");

-- CreateIndex
CREATE INDEX "UserInventoryItemKeychain_itemId_idx" ON "UserInventoryItemKeychain"("itemId");

-- CreateIndex
CREATE UNIQUE INDEX "UserInventoryItemKeychain_userInventoryItemId_slot_key" ON "UserInventoryItemKeychain"("userInventoryItemId", "slot");

-- CreateIndex
CREATE INDEX "InventoryRecovery_userId_idx" ON "InventoryRecovery"("userId");

-- CreateIndex
CREATE UNIQUE INDEX "Rule_name_key" ON "Rule"("name");

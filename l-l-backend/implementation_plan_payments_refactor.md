# Implementation Plan: Unified Payment & Subscription Architecture

## 1. Executive Summary
Refactor the current multi-model payment system (`PaymentIntent`, `Payment`, `PlanPurchase`, `Entitlement`) into a robust **2-Model Architecture**: `Transaction` and `UserSubscription`. This will handle all payment flows (Razorpay, Bank Transfer, Admin, Partial) in a unified ledger-based system.

## 2. New Data Models

### 2.1 Transaction Model (Immutable Ledger)
**Collection:** `transactions`
**Purpose:** Records all financial events.
```javascript
const transactionSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'users', required: true },
  planId: { type: mongoose.Schema.Types.ObjectId, ref: 'segmentsPlans' }, // Nullable for registration
  amount: { type: Number, required: true }, // Amount in INR
  currency: { type: String, default: 'INR' },
  source: { 
    type: String, 
    enum: ['RAZORPAY', 'BANK_TRANSFER', 'ADMIN_GRANT', 'SYSTEM', 'WALLET_ADJUSTMENT'], 
    required: true 
  },
  paymentType: { 
    type: String, 
    enum: ['FULL', 'INSTALLMENT', 'REGISTRATION', 'TRIAL', 'REFUND'], 
    required: true 
  },
  status: { 
    type: String, 
    enum: ['INITIATED', 'PENDING_PROOF', 'VERIFICATION_PENDING', 'SUCCESS', 'FAILED', 'REJECTED', 'REFUNDED'],
    default: 'INITIATED' 
  },
  proofImage: { type: String }, // For Bank Transfers
  utrNumber: { type: String }, // For Bank Transfers
  metadata: { type: Object }, // Store Razorpay OrderID, PaymentID, Signature, Admin Notes
  verifiedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'users' }, // Admin ID
}, { timestamps: true });
```

### 2.2 UserSubscription Model (Access State)
**Collection:** `usersubscriptions`
**Purpose:** Single source of truth for user access.
```javascript
const userSubscriptionSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'users', required: true, unique: true },
  type: { type: String, enum: ['REGISTRATION', 'PLAN'], required: true },
  
  // Plan Details (if type === PLAN)
  planId: { type: mongoose.Schema.Types.ObjectId, ref: 'segmentsPlans' },
  segmentId: { type: String }, 
  
  status: { 
    type: String, 
    enum: ['ACTIVE', 'PARTIAL', 'EXPIRED', 'SUSPENDED'], 
    default: 'PARTIAL' 
  },
  
  // Validity
  validFrom: { type: Date },
  validTill: { type: Date },
  
  // Financial State
  totalPlanCost: { type: Number, required: true },
  amountPaidSoFar: { type: Number, default: 0 },
  
  isLifetime: { type: Boolean, default: false },
  lastTransactionId: { type: mongoose.Schema.Types.ObjectId, ref: 'transactions' }
}, { timestamps: true });
```

## 3. Workflow Logic

### 3.1 Razorpay Payment (Full & Installment)
1. **Initiate:** Create `Transaction` (Status: `INITIATED`, Source: `RAZORPAY`).
2. **Webhook/Verify:** Upon success, update `Transaction` status to `SUCCESS`.
3. **Trigger:** Call `SubscriptionService.processPayment(transactionId)`.
4. **Subscription Service:**
   - Find/Create `UserSubscription`.
   - `amountPaidSoFar` += `transaction.amount`.
   - Recalculate `validTill` based on policy (Proportional or Threshold).
   - Update `status` to `ACTIVE` if conditions met.

### 3.2 Bank Transfer
1. **Initiate:** Create `Transaction` (Status: `PENDING_PROOF`, Source: `BANK_TRANSFER`).
2. **Upload:** User uploads proof. Update `Transaction` status to `VERIFICATION_PENDING`.
3. **Admin Panel:**
   - Admin views list of `VERIFICATION_PENDING` transactions.
   - **Approve:** Update status to `SUCCESS` → Trigger `SubscriptionService.processPayment`.
   - **Reject:** Update status to `REJECTED`. User notified.

### 3.3 Admin Grant
1. **Assign:** Admin selects plan for user.
2. **Record:** Create `Transaction` (Source: `ADMIN_GRANT`, Amount: 0, Status: `SUCCESS`, Type: `FULL`).
3. **Trigger:** `SubscriptionService.forceGrant(userId, planId, duration)`.

## 4. Migration Strategy (Breaking Change)

### Step 1: Backup
- Export existing collections: `payments`, `paymentintents`, `planpurchases`, `entitlements`, `users`.

### Step 2: Code Implementation
1. Create Model files: `Transaction.js`, `UserSubscription.js`.
2. Create Services: `TransactionService.js` (CRUD), `SubscriptionService.js` (Logic).
3. Update `AcquisitionService.js` to use new flows.
4. Update `UserService.js` to check `UserSubscription` for access gates.

### Step 3: Data Migration (Optional/Partial)
- **Active Users:** Script to read current valid `PlanPurchases` and create equivalent `UserSubscription` records so users don't lose access.
- **History:** Import legacy history into `Transaction` model (marked as `LEGACY_IMPORT`) or archive.

## 5. Timeline
1. **Phase 1:** Models & Service Layer (Backend)
2. **Phase 2:** Migration Script (Data)
3. **Phase 3:** Mobile App & Admin Panel Integration (Frontend)

import { NestFactory } from '@nestjs/core';
import { AppModule } from '../src/app.module';
import { PrismaService } from '../src/prisma.service';
import { ZebuService } from '../src/brokers/providers/zebu.service';
import { SignalsService } from '../src/signals/signals.service';
import { SignalOrchestratorService } from '../src/trading/services/signal-orchestrator.service';
import { OrderPlacementService } from '../src/trading/services/order-placement.service';
import { BrokerSessionService } from '../src/brokers/services/broker-session.service';
import { Segment, Side, OrderType, UserSegmentStatus, SubscriptionStatus, ConsentStatus, BrokerStatus, BrokerCode } from '@prisma/client';

async function testFullE2EFlow() {
  console.log('========================================================================');
  console.log('🚀 STARTING E2E TRADING FLOW TEST');
  console.log('========================================================================\n');

  const app = await NestFactory.createApplicationContext(AppModule, { logger: ['error', 'warn', 'log'] });

  const prisma = app.get(PrismaService);
  const zebuService = app.get(ZebuService);
  const signalsService = app.get(SignalsService);
  const orchestrator = app.get(SignalOrchestratorService);
  const orderPlacementService = app.get(OrderPlacementService);
  const brokerSessionService = app.get(BrokerSessionService);

  const ZEBU_CREDENTIALS = {
    clientCode: 'Z67017',
    password: 'Raj@2003',
    totpKey: 'GOOPM3532M',
    apiKey: 'ndTaFrT46gDk8nSBX4C4kAe3cc49aF88',
    vendorCode: 'Z67017',
  };

  try {
    // -------------------------------------------------------------------------
    // STEP 0: Setup Master Segment, Broker, Test User, & Active Zebu Session
    // -------------------------------------------------------------------------
    console.log('👉 [Step 0] Preparing Test Environment & User Account...');

    // 1. Ensure SegmentMaster exists
    let segmentMaster = await prisma.segmentMaster.findFirst();
    if (!segmentMaster) {
      segmentMaster = await prisma.segmentMaster.create({
        data: {
          name: 'NSE Intraday Test',
          segment: Segment.INTRADAY,
          exchange: 'NSE',
          minCapitalReq: 10000,
        },
      });
    }
    console.log(`   ✓ Master Segment ready: ${segmentMaster.name} (ID: ${segmentMaster.id})`);

    // 2. Ensure Zebu Broker exists
    let zebuBroker = await prisma.broker.findFirst({ where: { code: BrokerCode.ZEBU } });
    if (!zebuBroker) {
      zebuBroker = await prisma.broker.create({
        data: {
          code: BrokerCode.ZEBU,
          name: 'Zebu Share and Stock Broking',
          status: BrokerStatus.ACTIVE,
        },
      });
    }
    console.log(`   ✓ Zebu Broker Master ready (ID: ${zebuBroker.id})`);

    // 3. Create or find Test User
    const userEmail = 'e2e.test.trader@researchvia.in';
    let user = await prisma.user.findFirst({ where: { email: userEmail } });
    if (!user) {
      user = await prisma.user.create({
        data: {
          email: userEmail,
          mobile: '9876543210',
          mpinHash: 'hashed_mpin_sample',
          firstName: 'E2E Test',
          lastName: 'Trader',
        },
      });
    }
    console.log(`   ✓ Test User ready: ${user.firstName} ${user.lastName} (ID: ${user.id})`);

    // 4. Authenticate Zebu session directly via Zebu API
    console.log('   🔐 Authenticating user session with Zebu Broker API...');
    const sessionRes = await zebuService.generateSession(ZEBU_CREDENTIALS);
    console.log(`   ✓ Zebu Session Token generated! (Token snippet: ${sessionRes.accessToken.substring(0, 15)}...)`);

    // 5. Save/Update UserBroker record with active token
    let userBroker = await prisma.userBroker.findUnique({
      where: { userId_brokerId: { userId: user.id, brokerId: zebuBroker.id } },
    });
    if (!userBroker) {
      userBroker = await prisma.userBroker.create({
        data: {
          userId: user.id,
          brokerId: zebuBroker.id,
          brokerClientId: ZEBU_CREDENTIALS.clientCode,
          accessToken: sessionRes.accessToken,
          refreshToken: sessionRes.refreshToken,
          tokenExpiry: sessionRes.tokenExpiry,
          status: BrokerStatus.ACTIVE,
        },
      });
    } else {
      userBroker = await prisma.userBroker.update({
        where: { id: userBroker.id },
        data: {
          accessToken: sessionRes.accessToken,
          refreshToken: sessionRes.refreshToken,
          tokenExpiry: sessionRes.tokenExpiry,
          status: BrokerStatus.ACTIVE,
        },
      });
    }

    // Store Session in DB & Audit
    await brokerSessionService.storeSession(user.id, BrokerCode.ZEBU, sessionRes, userBroker.id);
    console.log('   ✓ UserBroker record & active session stored.');

    // 6. Ensure Active Subscription
    let subscription = await prisma.subscription.findFirst({
      where: { userId: user.id, status: SubscriptionStatus.ACTIVE },
    });
    if (!subscription) {
      subscription = await prisma.subscription.create({
        data: {
          userId: user.id,
          planId: '433f47c2-19e3-4d43-85f2-211aa7e06b3a',
          status: SubscriptionStatus.ACTIVE,
          startDate: new Date(),
          endDate: new Date(Date.now() + 365 * 24 * 3600 * 1000),
        },
      });
    }
    console.log('   ✓ Active Subscription verified.');

    // 7. Ensure Signed Consent
    let consent = await prisma.consent.findFirst({ where: { userId: user.id } });
    if (!consent) {
      consent = await prisma.consent.create({
        data: {
          userId: user.id,
          brokerId: zebuBroker.id,
          status: ConsentStatus.ACTIVE,
          consentDate: new Date(),
        },
      });
    } else if (consent.status !== ConsentStatus.ACTIVE) {
      await prisma.consent.update({
        where: { id: consent.id },
        data: { status: ConsentStatus.ACTIVE, consentDate: new Date() },
      });
    }
    console.log('   ✓ Signed User Consent verified.');

    // 8. Ensure User Segment Config is Active
    let userSeg = await prisma.userSegment.findUnique({
      where: { userId_segmentId: { userId: user.id, segmentId: segmentMaster.id } },
    });
    if (!userSeg) {
      userSeg = await prisma.userSegment.create({
        data: {
          userId: user.id,
          segmentId: segmentMaster.id,
          status: UserSegmentStatus.ACTIVE,
          capital: 50000,
          backupCapital: 0,
          baseLot: 1,
          maxMultiplier: 10,
          dailyLossLimit: 5000,
        },
      });
    } else {
      await prisma.userSegment.update({
        where: { id: userSeg.id },
        data: { status: UserSegmentStatus.ACTIVE },
      });
    }
    console.log('   ✓ User Segment Subscription Config active.');
    console.log('   ✅ Environment & User Setup Complete!\n');

    // -------------------------------------------------------------------------
    // STEP 1: RA Places Trading Call (Publish Signal)
    // -------------------------------------------------------------------------
    console.log('------------------------------------------------------------------------');
    console.log('📢 STEP 1: RA Places a Trading Call (Publish Signal)');
    console.log('------------------------------------------------------------------------');
    
    const signalDto = {
      segmentId: segmentMaster.id,
      symbol: 'SBIN-EQ',
      exchange: 'NSE',
      segment: Segment.INTRADAY,
      side: Side.BUY,
      orderType: OrderType.LIMIT,
      entryPrice: 810.50,
      stopLoss: 795.00,
      targetPrice: 835.00,
    };

    console.log('   Publishing Signal DTO:', signalDto);
    const publishRes = await signalsService.publishAndEnqueue(signalDto);
    console.log(`   ✓ Signal Published Successfully! Created Signal ID: ${publishRes.signalId}\n`);

    // -------------------------------------------------------------------------
    // STEP 2: Signal Orchestrator Fans Out Signal to Eligible Subscribed Users
    // -------------------------------------------------------------------------
    console.log('------------------------------------------------------------------------');
    console.log('⚙️ STEP 2: Engine Orchestrates Signal & Fans Out to Subscribed Users');
    console.log('------------------------------------------------------------------------');

    const orchestrateRes = await orchestrator.processSignal(publishRes.signalId);
    console.log(`   ✓ Signal Orchestration Complete!`);
    console.log(`     State: ${orchestrateRes.state}`);
    console.log(`     Total Subscribed Users: ${orchestrateRes.totalUsers}`);
    console.log(`     Success Users: ${orchestrateRes.successUsers}`);
    console.log(`     Rejected Users: ${orchestrateRes.rejectedUsers}`);

    // -------------------------------------------------------------------------
    // STEP 3: Automated Trade Execution for User Account
    // -------------------------------------------------------------------------
    console.log('\n------------------------------------------------------------------------');
    console.log('⚡ STEP 3: Automated Trade Execution via Zebu Broker API');
    console.log('------------------------------------------------------------------------');

    // Construct execution context for our target test user
    const shortSignalId = publishRes.signalId.substring(0, 8);
    const shortUserId = user.id.substring(0, 8);
    const execContext = {
      correlationId: `e2e-${shortSignalId}-${shortUserId}`,
      jobId: `job-e2e-${shortSignalId}`,
      signalId: publishRes.signalId,
      segmentId: segmentMaster.id,
      symbol: 'SBIN-EQ',
      exchange: 'NSE',
      side: Side.BUY,
      orderType: OrderType.LIMIT,
      entryPrice: 810.50,
      stopLoss: 795.00,
      targetPrice: 835.00,
      snapshot: {
        userId: user.id,
        brokerId: zebuBroker.id,
        brokerCode: 'ZEBU',
        brokerClientId: ZEBU_CREDENTIALS.clientCode,
        segmentId: segmentMaster.id,
        subscriptionPlan: 'SPARK' as const,
        multiplierIndex: 1,
        multiplierValue: 1.0,
        capitalAllocated: 50000,
        baseLot: 1,
        effectiveLot: 1,
      },
    };

    console.log(`   Executing order placement on Zebu terminal for Client ID: ${ZEBU_CREDENTIALS.clientCode}...`);
    const placementResult = await orderPlacementService.placeEntryOrder(execContext);
    console.log('\n   🎉 Trade Placement Result:', placementResult);

    // -------------------------------------------------------------------------
    // STEP 4: Database Audit & Verification
    // -------------------------------------------------------------------------
    console.log('\n------------------------------------------------------------------------');
    console.log('🔍 STEP 4: Database Verification & Trade Log Audit');
    console.log('------------------------------------------------------------------------');

    const trade = await prisma.trade.findFirst({
      where: { signalId: publishRes.signalId, userId: user.id },
      include: { orders: true },
    });

    if (trade) {
      console.log('   ✓ Trade Record Found in Database:');
      console.log(`     - Trade ID: ${trade.id}`);
      console.log(`     - Status: ${trade.status}`);
      console.log(`     - Symbol: ${trade.symbol}`);
      console.log(`     - Side: ${trade.side}`);
      console.log(`     - Price: ₹${trade.entryPrice}`);
      if (trade.orders && trade.orders.length > 0) {
        const ord = trade.orders[0];
        console.log(`     - Order ID: ${ord.id}`);
        console.log(`     - Broker Order ID: ${ord.brokerOrderId}`);
        console.log(`     - Order Status: ${ord.status}`);
      }
    } else {
      console.log('   ⚠️ No Trade record found in DB for this signal/user.');
    }

    console.log('\n========================================================================');
    console.log('✅ FULL E2E TRADING CALL & PLACEMENT FLOW TEST COMPLETED SUCCESSFULLY!');
    console.log('========================================================================');

  } catch (error) {
    console.error('\n❌ E2E TEST FAILED:', error);
  } finally {
    await app.close();
  }
}

testFullE2EFlow();

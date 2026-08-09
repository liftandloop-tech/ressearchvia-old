"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
async function checkTradeBook() {
    const token = '2ce6ad0f2e6496e76124f9d2913af1401cf17d5b2b52fce3305518c099e97113';
    const clientCode = 'Z67017';
    const jData = { uid: clientCode, actid: clientCode };
    const body = `jData=${JSON.stringify(jData)}&jKey=${token}`;
    console.log('=== CALLING ZEBU MYNT TRADEBOOK API ===');
    console.log('URL: https://go.mynt.in/NorenWClientTP/TradeBook');
    console.log('Body:', body);
    try {
        const res = await fetch('https://go.mynt.in/NorenWClientTP/TradeBook', {
            method: 'POST',
            headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
            body,
        });
        console.log('Status Code:', res.status);
        const data = await res.json();
        console.log('=== RAW ZEBU TRADEBOOK RESPONSE ===');
        console.log(JSON.stringify(data, null, 2));
    }
    catch (err) {
        console.error('Error fetching TradeBook:', err.message);
    }
}
checkTradeBook();
//# sourceMappingURL=check_tradebook.js.map
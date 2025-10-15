const mn = require('electrum-mnemonic')
console.log(mn.generateMnemonic()) // default segwit bech32 wallet
console.log(mn.generateMnemonic({ prefix: mn.PREFIXES.segwit })) // explicit segwit bech32 wallet
console.log(mn.generateMnemonic({ prefix: mn.PREFIXES.standard })) // legacy p2pkh wallet (base58 address starting with 1)
console.log(mn.generateMnemonic({ prefix: mn.PREFIXES['2fa'] })) // 2fa legacy
console.log(mn.generateMnemonic({ prefix: mn.PREFIXES['2fa-segwit'] })) 
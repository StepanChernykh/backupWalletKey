#!/bin/bash

#$1 is wallet|keys
#$2 is btg|btc|bth|ltc|eth|etc
#$3 is path to wallet.dat or keys
#$4 is path to node (to regtest)

dirWalletBackup="C:/Users/User/Desktop/script/btg/backups"

#tmp
dirNodeBTG="C:/Users/User/Desktop/script/btg/node"
dirNodeBTC="C:/Users/User/Desktop/script/btg/node"
dirNodeBTH="C:/Users/User/Desktop/script/btg/node"
dirNodeLTC="C:/Users/User/Desktop/script/btg/node"

dirKeystoreETC="C:/Users/User/Desktop/script/btg/node/ethereum-classic/keystore"
dirKeystoreETH="C:/Users/User/Desktop/script/btg/node/ethereum/keystore"

#dirWalletBTG="C:/Users/User/Desktop/script/btg/node/bitcoingold/.bitcoingold/regtest"
#dirWalletBTC="C:/Users/User/Desktop/script/btg/node/bitcoin/.bitcoin/regtest"
#dirWalletBTH="C:/Users/User/Desktop/script/btg/node/bitcoincash/.bitcoincash/regtest"
#dirWalletLTC="C:/Users/User/Desktop/script/btg/node/litecoin/.litecoin/regtest"

nameBTG="bitcoin-gold"
nameBTC="bitcoin"
nameBTH="bitcoin-cash"
nameLTC="litecoin"

datadirBTG=""
datadirBTC=""
datadirBTH=""
datadirLTC=""

cliBTG="docker exec --user bitcoingold bitcoin-gold bgold-cli -regtest"
cliBTC="docker exec bitcoin bitcoin-cli"
cliBTH="docker exec --user bitcoin bitcoin-cash bitcoin-cli -regtest"
cliLTC="docker exec --user litecoin litecoin litecoin-cli -regtest"
#cliBTG="bgold-cli -regtest -datadir=$datadirBTG"
#cliBTC="bitcoin-cli -datadir=$datadirBTC"
#cliBTH="bitcoin-cli -regtest -datadir=$datadirBTH"
#cliLTC="litecoin-cli -regtest -datadir=$datadirLTC"

#$1 = btg|btc|bth|ltc
#$2 = $dirWalletBackup
#$3 = bitCli
function importKeysBitFork {
		walletLatest=$(ls -t $2"/"$1 | grep txt | head -1)
		strInFile=$(wc -l $2"/"$1"/"$walletLatest | awk '{print $1}')
		#> $dirNodeBTG"/testfile.txt"  #tmp
		count=0
		let "lastKeyNum = strInFile - 2"
		while read line
		do 
			#import privKey of node
			if [[ $count -gt 6 && $count -lt $lastKeyNum ]]
			then
				privatKey=`echo ${line} | awk '{print $1}'`
				dopParametr=`echo ${line} | awk '{print $3}'`
				#echo $dopParametr
				metka=$(echo $dopParametr | cut -d'=' -f 1)
				#echo $metka
				if [[ $metka == "label" ]]
				then
					account=$(echo $dopParametr | cut -d'=' -f 2)
					$3 importprivkey $privatKey $account
					#echo $privatKey" account="$account >> $dirNodeBTG"/testfile.txt"  #tmp
				else
					$3 importprivkey $privatKey
					#echo $privatKey >> $dirNodeBTG"/testfile.txt"  #tmp
				fi
			fi
			let "count += 1"
		done < $2"/"$1"/"$walletLatest
		let "count -= 9"
		echo "import "$count" privat keys in "$1" wallet"
}

if [[ $1 = "wallet" ]]
then
	if [[ $2 = "btg" ]]
	then
		walletLatest=$(ls -t $dirWalletBackup"/bitcoin-gold" | grep dat | head -1)
		scp $dirWalletBackup"/bitcoin-gold/"$walletLatest $dirWalletBTG"/wallet.dat" > /dev/null 2>&1
		#reindex node
	elif [[ $2 = "btc" ]]
	then
		walletLatest=$(ls -t $dirWalletBackup"/bitcoin" | grep dat | head -1)
		scp $dirWalletBackup"/bitcoin/"$walletLatest $dirWalletBTC"/wallet.dat" > /dev/null 2>&1
		#reindex node
	elif [[ $2 = "bth" ]]
	then
		walletLatest=$(ls -t $dirWalletBackup"/bitcoin-cash" | grep dat | head -1)
		scp $dirWalletBackup"/bitcoin-cash/"$walletLatest $dirWalletBTH"/wallet.dat" > /dev/null 2>&1
		#reindex node
	elif [[ $2 = "ltc" ]]
	then
		walletLatest=$(ls -t $dirWalletBackup"/litecoin" | grep dat | head -1)
		scp $dirWalletBackup"/litecoin/"$walletLatest $dirWalletLTC"/wallet.dat" > /dev/null 2>&1
		#reindex node
	else
		echo "incorrect second parametr "$2 
	fi
elif [[ $1 = "keys" ]]
then
	if [[ $2 = "btg" ]]
	then
		importKeysBitFork $nameBTG $dirWalletBackup "$cliBTG"
	elif [[ $2 = "btc" ]]
	then
		importKeysBitFork $nameBTC $dirWalletBackup "$cliBTC"
	elif [[ $2 = "bth" ]]
	then
		importKeysBitFork $nameBTH $dirWalletBackup "$cliBTH"
	elif [[ $2 = "ltc" ]]
	then
		importKeysBitFork $nameLTC $dirWalletBackup "$cliLTC"
	elif [[ $2 = "eth" ]]
	then
		scp $dirWalletBackup"/ethereum/*" $dirKeystoreETH > /dev/null 2>&1  
	elif [[ $2 = "etc" ]]
	then
		scp $dirWalletBackup"/ethereum-classic/*" $dirKeystoreETC > /dev/null 2>&1
	else
		echo "incorrect second parametr "$2
	fi
else
	echo "incorrect first parametr "$1
fi


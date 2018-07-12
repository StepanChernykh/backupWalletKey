#!/bin/bash

#итого:
#@TODO: нужно настроить все пути к файлам и нодам
#@TODO: нужно настроить scp и cron

#предположительно здесь backup'ы лежат по умолчанию
#Bitcoin
#C:/users/appdata/roaming/НазваниеМонеты
#Ethereum
#Windows: C:\Users\username\%appdata%\Roaming\Ethereum\keystore
#Linux: ~/.ethereum/keystore
#Mac: ~/Library/Ethereum/keystore

#путь до директории tmp
fromBTG=""
fromBTH=""
fromBTC=""
fromLTC=""
#путь до директории keystore (включительно)
fromETH=""
fromETC=""
#путь до директории с бекапами на сервере
to=""
filename=backupsTime.txt

containerNameBitcoinGold="bitcoin-gold"
datadirBTG=""
containerNameBitcoinCash="bitcoin-cash"
datadirBTH=""
containerNameBitcoin="bitcoin"
datadirBTC=""
containerNameLitecoin="litecoin"
datadirLTC=""
containerNameEthereum="ethereum"
containerNameEthereumClassik="ethereum-classic"

#@TODO : бесполезная херня?
mkdir -p "${to}/"$containerNameBitcoinGold
mkdir -p "${to}/"$containerNameBitcoinCash
mkdir -p "${to}/"$containerNameBitcoin
mkdir -p "${to}/"$containerNameLitecoin
mkdir -p "${to}/"$containerNameEthereum
mkdir -p "${to}/"$containerNameEthereumClassik

function backupWallet {
	#извлечение инфы о версии wallet.dat
	local NodeResponse
	local result=$2
	if [[ $1 = 'bitcoin-cash' ]]
	then
		NodeResponse=$(bitcoin-cli -regtest -datadir=$datadirBTH getwalletinfo)
	elif [[ $1 = 'bitcoin' ]]
	then
		NodeResponse=$(bitcoin-cli -datadir=$datadirBTC getwalletinfo)
	elif [[ $1 = 'bitcoin-gold' ]]
	then
		NodeResponse=$(bgold-cli -regtest -datadir=$datadirBTG getwalletinfo)	
	elif [[ $1 = 'litecoin' ]]
	then
		NodeResponse=$(litecoin-cli -regtest -datadir=$datadirLTC getwalletinfo)
	fi
	
	local keypoololdest
	if [[  $1 = 'bitcoin'  ]]
	then
		keypoololdest=$(echo $NodeResponse | cut -d',' -f 6 | cut -d':' -f 2)
	else 
		keypoololdest=$(echo $NodeResponse | cut -d',' -f 7 | cut -d':' -f 2)
	fi
	#если нужно, обновить backup
	if [[ $keypoololdest -gt $result ]] 
	then
		result=$keypoololdest
		local date=$(date +%s)
		local dump
		local backup
		#запросы к ноде на создание backup'ов
		if [[ $1 = 'bitcoin-cash' ]]
		then
			dump=$(bitcoin-cli -regtest -datadir=$datadirBTH dumpwallet "tmp/"$date"walletBackup.txt")
			backup=$(bitcoin-cli -regtest -datadir=$datadirBTH backupwallet "tmp/"$date"walletBackup.dat")
		elif [[ $1 = 'bitcoin' ]]
		then
			dump=$(bitcoin-cli -datadir=$datadirBTC dumpwallet $date"walletBackup.txt")
			backup=$(bitcoin-cli -datadir=$datadirBTC backupwallet $date"walletBackup.dat")
		elif [[ $1 = 'bitcoin-gold' ]]
		then
			dump=$(bgold-cli -regtest -datadir=$datadirBTG dumpwallet "tmp/"$date"walletBackup.txt")
			backup=$(bgold-cli -regtest -datadir=$datadirBTG backupwallet "tmp/"$date"walletBackup.dat")
		elif [[ $1 = 'litecoin' ]]
		then
			dump=$(litecoin-cli -regtest -datadir=$datadirLTC dumpwallet "tmp/"$date"walletBackup.txt")
			backup=$(litecoin-cli -regtest -datadir=$datadirLTC backupwallet "tmp/"$date"walletBackup.dat")
		fi
		
		#@TODO: настроить scp
		
		if [[ $1 = 'bitcoin-cash' ]]
		then
			scp "${fromBTH}/tmp/"$date"walletBackup.*" "${to}/"$1 
		elif [[ $1 = 'bitcoin' ]]
		then
			scp "${fromBTC}/tmp/"$date"walletBackup.*" "${to}/"$1 
		elif [[ $1 = 'bitcoin-gold' ]]
		then
			scp "${fromBTG}/tmp/"$date"walletBackup.*" "${to}/"$1 
		elif [[ $1 = 'litecoin' ]]
		then
			scp "${fromLTC}/tmp/"$date"walletBackup.*" "${to}/"$1 
		fi
		
	fi
	echo $result
}

function backupKey {
	#получение текущего количества ключей
	local tmpCount
	if [[ $1 = 'ethereum' ]]
	then
		tmpCount=$(ls -f "${fromETH}" | wc -l) 
	elif [[ $1 = 'ethereum-classic' ]]
	then
		tmpCount=$(ls -f "${fromETC}" | wc -l) 
	fi
	
	local result=$2
	
	#если нужно, обновить backup
	if [[ $tmpCount -gt $result ]] 
	then
		result=$tmpCount
		#копирование файлов, созданных за последний час
		#@TODO : проверить путь и, если нужно, настроить время
		if [[ $1 = 'ethereum' ]]
		then
			find "${fromETH}/" -type f -mmin -60 -exec scp {} "${to}/"$1 \;
		elif [[ $1 = 'ethereum-classic' ]]
		then
			find "${fromETC}/" -type f -mmin -60 -exec scp {} "${to}/"$1 \;
		fi
	fi
	echo $result
}

#массив с timestamp'ами и count'ерами из файла
declare -a checkNeedBackupsArray
if [[ -f $filename ]]
then
	readarray checkNeedBackupsArray < $filename
	#checkNeedBackupsArray=(`cat "$filename"`)
else
	for (( i = 0 ; i < 6 ; i++))
	do
	checkNeedBackupsArray[$i]=0
	done
fi

#очистка/создание файла
> $filename

#BitFork
checkNeedBackupsArray[0]=$(backupWallet $containerNameBitcoinGold ${checkNeedBackupsArray[0]})
checkNeedBackupsArray[1]=$(backupWallet $containerNameBitcoin ${checkNeedBackupsArray[1]})
checkNeedBackupsArray[2]=$(backupWallet $containerNameBitcoinCash ${checkNeedBackupsArray[2]})
checkNeedBackupsArray[3]=$(backupWallet $containerNameLitecoin ${checkNeedBackupsArray[3]})

#EtherFork
checkNeedBackupsArray[4]=$(backupKey $containerNameEthereum ${checkNeedBackupsArray[4]})
checkNeedBackupsArray[5]=$(backupKey $containerNameEthereumClassik ${checkNeedBackupsArray[5]})

for (( i = 0 ; i < 6 ; i++))
do
echo ${checkNeedBackupsArray[$i]}" " >> $filename;
done

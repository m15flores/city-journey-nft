package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"math/big"
	"os"
	"strings"

	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/ethereum/go-ethereum/ethclient"
)

type City struct {
	CityName  string `json:"cityName"`
	Latitude  int64  `json:"latitude"`
	Longitude int64  `json:"longitude"`
	FromDate  int64  `json:"fromDate"`
	ToDate    int64  `json:"toDate"`
}

func main() {

	cities, err := loadCities("cities.json")
	if err != nil {
		log.Fatal(err)
	}

	client, err := connectClient("https://arb1.arbitrum.io/rpc")
	if err != nil {
		log.Fatal(err)
	}

	auth, err := buildAuth(os.Getenv("PRIVATE_KEY"), big.NewInt(42161))
	if err != nil {
		log.Fatal(err)
	}

	contract, err := NewCityJourneyNFT(common.HexToAddress("0xA066b02716BEFaAb59B370224Af1c8C0bBEA1eDd"), client)
	if err != nil {
		log.Fatal(err)
	}

	if err := mintCities(client, contract, auth, cities); err != nil {
		log.Fatal(err)
	}
}

func loadCities(jsonFile string) ([]City, error) {
	data, err := os.ReadFile(jsonFile)
	if err != nil {
		return nil, fmt.Errorf("read %s: %w", jsonFile, err)
	}

	var cities []City
	err = json.Unmarshal(data, &cities)
	return cities, err
}

func connectClient(link string) (*ethclient.Client, error) {
	client, err := ethclient.Dial(link)
	return client, err
}

func buildAuth(privateKeyHex string, chainID *big.Int) (*bind.TransactOpts, error) {
	privateKeyHex = strings.TrimPrefix(privateKeyHex, "0x")
	privateKey, err := crypto.HexToECDSA(privateKeyHex)
	if err != nil {
		return nil, fmt.Errorf("parse private key: %w", err)
	}

	auth, err := bind.NewKeyedTransactorWithChainID(privateKey, chainID)
	if err != nil {
		return nil, fmt.Errorf("build transactor: %w", err)
	}

	return auth, err
}

func mintCities(client *ethclient.Client, contract *CityJourneyNFT, auth *bind.TransactOpts, cities []City) error {
	nonce, err := client.PendingNonceAt(context.Background(), auth.From)
	if err != nil {
		return err
	}

	for _, city := range cities {
		auth.Nonce = big.NewInt(int64(nonce))

		tx, err := contract.Mint(
			auth,
			city.CityName,
			big.NewInt(city.Latitude),
			big.NewInt(city.Longitude),
			big.NewInt(city.FromDate),
			big.NewInt(city.ToDate),
		)
		if err != nil {
			return err
		}

		fmt.Println("Minted:", city.CityName, "tx:", tx.Hash().Hex())
		nonce++
	}
	return nil
}

from scripts.functions import *


def main():
    active_network = network.show_active()
    print("Current Network:" + active_network)

    admin, creator, consumer, iwan = get_accounts(active_network)

    try:
        if active_network in LOCAL_NETWORKS:
            nft=NFT.deploy(10000, 3125, 3, "http://isotop.top/", addr(admin))
            nft.setupNonAuctionSaleInfo(0, chain.time())

        if active_network in TEST_NETWORKS:
            nft=NFT.deploy(10000, 3125, 3, "http://isotop.top/", addr(admin))
            nft.setupNonAuctionSaleInfo(0, chain.time())

    except Exception:
        console.print_exception()
        # Test net contract address


if __name__ == "__main__":
    main()

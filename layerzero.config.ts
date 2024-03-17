import { EndpointId } from '@layerzerolabs/lz-definitions'

const sepoliaContract = {
    eid: EndpointId.SEPOLIA_V2_TESTNET,
    contractName: 'MyOAppVoting',
}

const opSepoliaContract = {
    eid: EndpointId.OPTSEP_V2_TESTNET,
    contractName: 'MyOAppVoting',
}

const arbSepoliaContract = {
    eid: EndpointId.ARBSEP_V2_TESTNET,
    contractName: 'MyOAppVoting',
}

export default {
    contracts: [
        {
            contract: sepoliaContract,
        },
        {
            contract: opSepoliaContract,
        },
        {
            contract: arbSepoliaContract,
        },
    ],
    connections: [
        {
            from: sepoliaContract,
            to: opSepoliaContract,
        },
        {
            from: sepoliaContract,
            to: arbSepoliaContract,
        },
        {
            from: opSepoliaContract,
            to: sepoliaContract,
        },
        {
            from: opSepoliaContract,
            to: arbSepoliaContract,
        },
        {
            from: arbSepoliaContract,
            to: sepoliaContract,
        },
        {
            from: arbSepoliaContract,
            to: opSepoliaContract,
        },
    ],
}

%lang starknet

const erc20_addr = 12345
const admin = 67890 

@external
func up():
    tempvar class_hash
    tempvar user_registry
    %{ 
        ids.class_hash = declare("./build/qf_pool.json").class_hash 

        ids.user_registry = deploy_contract("./build/user_registry.json").contract_address

        deploy_contract("./build/coreV2.json", [ids.class_hash, ids.user_registry, ids.erc20_addr, ids.admin])
    %}
    return ()
end

@external
func down():
    %{ assert False, "Not implemented" %}
    return ()
end
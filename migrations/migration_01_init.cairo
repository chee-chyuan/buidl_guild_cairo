%lang starknet

const erc20_addr = 2087021424722619777119509474943472645767659996348769578120564519014510906823
const admin = 451599388488372420441116084417277127504010690560639326384514568067339491613 

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
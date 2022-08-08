%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from src.interfaces.IQfPool import IQfPool
from tests.core.utils.ICore import ICore

const ADMIN = 12345223424

@view
func __setup__():
    tempvar qf_pool_class_hash
    tempvar user_registry_address
    %{
        context.qf_class_hash = declare(
            "./src/qf_pool.cairo", 
        ).class_hash

        ids.qf_pool_class_hash = context.qf_class_hash

        context.user_registry = deploy_contract(
            "./src/user_registry.cairo", 
            []).contract_address

        ids.user_registry_address = context.user_registry

        context.contract_address = deploy_contract(
            "./src/core.cairo", 
            [ids.qf_pool_class_hash,
             ids.user_registry_address,
             1
            ]).contract_address
    %}
    return ()
end

@view
func test_deploy_contract{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
}():
    tempvar contract_address
    %{
        ids.contract_address = context.contract_address
    %}
    let (salt_before) = ICore.get_salt(contract_address=contract_address)
    assert salt_before = 0

    let (current_pool_id_before) = ICore.get_current_pool_id(contract_address=contract_address)
    assert current_pool_id_before = 1

    let (admin) = ICore.get_admin(contract_address=contract_address)

    %{
        stop_prank_callable = start_prank(ids.admin, target_contract_address=ids.contract_address)
        # print(f"salt_before: {ids.salt_before}")
        # print(f"current_pool_id_before: {ids.current_pool_id_before}")
    %}


    ICore.deploy_pool(contract_address=contract_address, 
                        vote_start_time_=100,
                        vote_end_time_=500,
                        stream_start_time_=500,
                        stream_end_time_= 800
                        )
    let (salt_after) = ICore.get_salt(contract_address=contract_address)
    assert salt_after = 1

    let (current_pool_id_after) = ICore.get_current_pool_id(contract_address=contract_address)
    assert current_pool_id_after = 2

    let (pool_addr) = ICore.get_pool_address(contract_address=contract_address, pool_id=1)

    # check pool info by calling the pool directly
    let (vote_start) = IQfPool.get_vote_start_time(contract_address=pool_addr)
    assert vote_start = 100

    %{
        # print(f"salt_after: {ids.salt_after}")
        # print(f"current_pool_id_after: {ids.current_pool_id_after}")
        # print(f"pool_addr: {ids.pool_addr}")
        stop_prank_callable()
    %}

    return ()
end
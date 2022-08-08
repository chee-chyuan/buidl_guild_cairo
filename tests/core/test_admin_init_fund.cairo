%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from tests.core.utils.ICore import ICore
from openzeppelin.token.erc20.IERC20 import IERC20
from starkware.cairo.common.uint256 import Uint256
from tests.qf_pool.utils.IQfPool import IQfPool

const ADMIN = 45321342
const USER = 13434
const TIME_START = 1159925704
const TIME_END = 1869925704

@view
func __setup__():
    tempvar user_registry_address
    tempvar erc20_address
    tempvar qf_pool_class_hash
    %{
         context.erc20_address = deploy_contract(
            "./src/MockErc20.cairo",
            [1111,
             1111,
             18,
             1000000,1000000,
             ids.ADMIN]
            ).contract_address

         ids.erc20_address = context.erc20_address

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
             ids.erc20_address,
            ]).contract_address
    %}
    return ()
end

func create_new_pool{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
}() -> (addr: felt) :
    tempvar contract_address
    %{
        ids.contract_address = context.contract_address
    %}

    let (admin) = ICore.get_admin(contract_address=contract_address)

    %{
        stop_prank_callable = start_prank(ids.admin, target_contract_address=ids.contract_address)
    %}

    ICore.deploy_pool(contract_address=contract_address, 
                        vote_start_time_=TIME_START,
                        vote_end_time_=TIME_END,
                        stream_start_time_=500,
                        stream_end_time_= 800
                        )

    let (pool_addr) = ICore.get_pool_address(contract_address=contract_address, pool_id=1)

    %{
        stop_prank_callable()
    %}

    return (addr=pool_addr)
end



func transfer_funds_to_user_and_approve{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
}():
    tempvar erc20_address
    tempvar contract_address
    %{
        ids.erc20_address = context.erc20_address
        ids.contract_address = context.contract_address
        stop_prank_admin = start_prank(ids.ADMIN, target_contract_address=ids.erc20_address)
    %}
        let (admin) = ICore.get_admin(contract_address=contract_address)
        IERC20.transfer(contract_address=erc20_address, recipient=admin, amount=Uint256(10000,0))
    %{
        stop_prank_admin()
        stop_prank_user = start_prank(ids.admin, target_contract_address=ids.erc20_address)
    %}

        IERC20.approve(contract_address=erc20_address, spender=contract_address, amount=Uint256(99999999,999999))

    %{
        stop_prank_user()
    %}

    return ()
end

@view
func test_init_matched_fund{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
}():

    let (pool_addr) = create_new_pool()
    transfer_funds_to_user_and_approve()

    tempvar contract_address
    %{
        ids.contract_address = context.contract_address
    %}

    let (admin) = ICore.get_admin(contract_address=contract_address)

    %{
        stop_prank_callable = start_prank(ids.admin, target_contract_address=ids.contract_address)
    %}

    # state before
    let (total_match_before) = IQfPool.get_total_match(contract_address=pool_addr)
    assert total_match_before = Uint256(0,0)

    ICore.admin_init_matched_fund_in_pool(
                            contract_address=contract_address, 
                            pool_id=1, 
                            amount=Uint256(100,0)
                        )

    # state after
    let (total_match_after) = IQfPool.get_total_match(contract_address=pool_addr)
    assert total_match_after = Uint256(100,0)

    %{
        stop_prank_callable()
    %}

    return ()
end
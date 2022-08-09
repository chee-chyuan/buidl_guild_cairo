%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.uint256 import Uint256
from tests.core.utils.ICore import ICore
from openzeppelin.token.erc20.IERC20 import IERC20
from src.interfaces.IUserRegistrar import IUserRegistrar

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
             ids.ADMIN
            ]).contract_address
    %}
    return ()
end

func register_user{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
}(user: felt): 
    tempvar user_registry_addr
    %{
        ids.user_registry_addr = context.user_registry
        stop_prank_callable = start_prank(ids.user, target_contract_address=ids.user_registry_addr)
    %}

    let prefix = 'a'
    let suffix = 'ab'
    let ipfs_len = 1
    let (ipfs) = alloc()
    assert ipfs[0] = 'xxxx'

    IUserRegistrar.register(contract_address=user_registry_addr,
                            github_prefix=prefix, 
                            github_suffix=suffix,
                            ipfs_url_len=ipfs_len,
                            ipfs_url=ipfs
                            )

    %{
        stop_prank_callable()
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
        IERC20.transfer(contract_address=erc20_address, recipient=USER, amount=Uint256(1000,0))
    %{
        stop_prank_admin()
        stop_prank_user = start_prank(ids.USER, target_contract_address=ids.erc20_address)
    %}

        IERC20.approve(contract_address=erc20_address, spender=contract_address, amount=Uint256(99999999,999999))

    %{
        stop_prank_user()
    %}

    return ()
end

func add_buidl_and_project{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
}():
    alloc_locals

    tempvar contract_address
    %{
        ids.contract_address=context.contract_address
        stop_prank_callable = start_prank(ids.USER, target_contract_address=ids.contract_address)
    %}
    local contract_address = contract_address

    let ipfs_len = 2
    let (ipfs) = alloc()
    assert ipfs[0] = 'a'
    assert ipfs[1] = 'b'

    ICore.add_buidl(contract_address=contract_address, ipfs_len=ipfs_len, ipfs=ipfs)
    ICore.add_buidl_to_pool(contract_address=contract_address, buidl_id=1, pool_id=1)
    
    %{
        stop_prank_callable()
    %}
    return ()
end


func init_matched_pool{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
}(pool_id: felt):
    
    tempvar contract_address
    %{
        ids.contract_address = context.contract_address
    %}

    let (admin) = ICore.get_admin(contract_address=contract_address)

    %{
        stop_prank_callable = start_prank(ids.admin, target_contract_address=ids.contract_address)
    %}

    ICore.admin_init_matched_fund_in_pool(
                            contract_address=contract_address, 
                            pool_id=pool_id, 
                            amount=Uint256(100,0)
                        )

    %{
        stop_prank_callable()
    %}

    return ()
end

@view 
func test_claim{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
}():
    alloc_locals
    let (pool_addr) = create_new_pool()
    local pool_addr = pool_addr
    register_user(user=USER)
    add_buidl_and_project()
    transfer_funds_to_user_and_approve()
    # init_matched_pool(1)
    tempvar contract_address
    %{
        ids.contract_address=context.contract_address
    %}

    %{
    %}

    return ()
end

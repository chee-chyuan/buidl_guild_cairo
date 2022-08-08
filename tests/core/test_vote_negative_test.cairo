%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc
from tests.core.utils.ICore import ICore
from src.interfaces.IUserRegistrar import IUserRegistrar
from starkware.cairo.common.uint256 import Uint256

const ADMIN = 45321342
const USER = 13434
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
                        vote_start_time_=100,
                        vote_end_time_=500,
                        stream_start_time_=500,
                        stream_end_time_= 800
                        )

    let (pool_addr) = ICore.get_pool_address(contract_address=contract_address, pool_id=1)

    %{
        stop_prank_callable()
    %}

    return (addr=pool_addr)
end

@view
func test_cannot_vote_if_not_registered{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
}():
    tempvar contract_address
    %{
        ids.contract_address = context.contract_address
        expect_revert(error_message="User not registered")
    %}
    ICore.vote(contract_address=contract_address, pool_id=0, project_id=0, amount=Uint256(0,0))

    return ()
end

@view
func test_cannot_vote_if_pool_id_invalid{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
}():
    register_user(USER)
    tempvar contract_address
    %{
        ids.contract_address = context.contract_address
        stop_prank_callable = start_prank(ids.USER, target_contract_address=ids.contract_address)
        expect_revert(error_message="Invalid Pool Id")
    %}
    ICore.vote(contract_address=contract_address, pool_id=0, project_id=0, amount=Uint256(0,0))

    %{
        stop_prank_callable()
    %}
    return ()
end

@view
func test_cannot_vote_if_transfer_erc20_fails{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
}():
    register_user(USER)
    let (pool_addr) = create_new_pool()

    tempvar contract_address
    %{
        ids.contract_address = context.contract_address
        stop_prank_callable = start_prank(ids.USER, target_contract_address=ids.contract_address)
        expect_revert(error_message="Invalid Pool Id")
    %}

    ICore.vote(contract_address=contract_address, pool_id=1, project_id=0, amount=Uint256(1,0))

    %{
        stop_prank_callable()
    %}
    return ()
end
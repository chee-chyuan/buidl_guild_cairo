%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc
from tests.core.utils.ICore import ICore
from tests.qf_pool.utils.IQfPool import IQfPool
from src.interfaces.IUserRegistrar import IUserRegistrar

const USER = 13434
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
             ids.user_registry_address
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

@view
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
func test_add_buidl_to_pool{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
}():
    alloc_locals
    local pedersen_ptr_local: HashBuiltin* = pedersen_ptr 

    register_user(USER)
    let (pool_addr) = create_new_pool()

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

    # state before
    let (len_before) = ICore.get_user_buidl_project_len(contract_address=contract_address, user_addr=USER)
    assert len_before = 0

    ICore.add_buidl_to_pool(contract_address=contract_address, buidl_id=1, pool_id=1)

    # state after
    let (len_after) = ICore.get_user_buidl_project_len(contract_address=contract_address, user_addr=USER)
    assert len_after = 1

    let (mapping) = ICore.get_user_buidl_project_mapping(
                        contract_address=contract_address,
                        user_addr=USER,
                        index=0
                    )

    assert mapping.pool_id = 1
    assert mapping.pool_addr = pool_addr
    assert mapping.project_id = 1

    # directly call pool to check project
    let (project_info) = IQfPool.get_project_info(contract_address=pool_addr, project_id=1)
    assert project_info.ipfs_link_len = 2
    assert project_info.owner = USER

    %{
        stop_prank_callable()
    %}
    return ()
end


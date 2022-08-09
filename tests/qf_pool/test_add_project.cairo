%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc
from tests.qf_pool.utils.IQfPool import IQfPool

const ERC20_ADDR = 353534
const OWNER_ADDRESS = 123456
const VOTE_TIME_START = 1
const VOTE_TIME_END = 2
const STREAM_TIME_START = 3
const STREAM_TIME_END = 4

const PROJECT_OWNER = 353232
@view
func __setup__():
    %{
         context.contract_address = deploy_contract(
            "./src/qf_pool.cairo", 
            [ids.ERC20_ADDR,
             ids.OWNER_ADDRESS,
             ids.VOTE_TIME_START,
             ids.VOTE_TIME_END,
             ids.STREAM_TIME_START,
             ids.STREAM_TIME_END
            ]).contract_address
    %}
    return ()
end

@view
func test_add_project{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }():
    alloc_locals
    tempvar contract_address
    %{
        ids.contract_address = context.contract_address
    %}

    local contract_address = contract_address

    let link_len = 3
    let (link) = alloc()
    assert link[0] = 'a'
    assert link[1] = 'b'
    assert link[2] = 'c'

    let (reverse_owner_project_id_before) = IQfPool.get_reverse_user_project_id(contract_address=contract_address, owner=PROJECT_OWNER)
    assert reverse_owner_project_id_before = 0

    let (current_id_before) = IQfPool.get_current_project_id(contract_address=contract_address)
    assert current_id_before = 1

    IQfPool.add_project(contract_address=contract_address, owner=PROJECT_OWNER, ipfs_link_len=link_len, ipfs_link=link)

    # # revoked reference ==, and im too lazy to use local
    # tempvar contract_address
    # %{
    #     ids.contract_address = context.contract_address
    # %}

    let (current_id_after) = IQfPool.get_current_project_id(contract_address=contract_address)
    assert current_id_after = 2

    let (ipfs_link) = alloc()

    let (ipfs_link_len, ipfs_link) = IQfPool.get_project_ipfs_link(
                                        contract_address=contract_address,
                                        project_id=1,
                                        current_index=0,
                                        ipfs_len=link_len,
                                        link_len=0,
                                        link=ipfs_link
                                        )

    assert ipfs_link_len = link_len
    assert ipfs_link[0] = 'a'
    assert ipfs_link[1] = 'b'
    assert ipfs_link[2] = 'c'

    # # revoked reference ==, and im too lazy to use local
    # tempvar contract_address
    # %{
    #     ids.contract_address = context.contract_address
    # %}

    let (reverse_owner_project_id_after) = IQfPool.get_reverse_user_project_id(contract_address=contract_address, owner=PROJECT_OWNER)
    assert reverse_owner_project_id_after = 1

    let (project_return) = IQfPool.get_project_by_id(contract_address=contract_address, project_id=1)
    let (all_projects_len, all_projects) = IQfPool.get_all_projects(contract_address=contract_address)

    assert all_projects[0].owner = project_return.owner

    %{
        print(f"all_projects_len: {ids.all_projects_len}")
        # print(f"all_projects.owner: {memory[ids.all_projects]}"
        print(f"project_return.owner: {ids.project_return.owner}")
    %}

    return ()
end

@view
func test_only_one_project_per_owner{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }():
    tempvar contract_address
    %{
        ids.contract_address = context.contract_address
    %}

    let link_len = 1
    let (link) = alloc()
    assert link[0] = 'a'
    IQfPool.add_project(contract_address=contract_address, owner=PROJECT_OWNER, ipfs_link_len=link_len, ipfs_link=link)

    tempvar contract_address
    %{
        ids.contract_address = context.contract_address
    %}

    let link_len = 1
    let (link) = alloc()
    assert link[0] = 'a'

    %{ expect_revert(error_message="Owner already has a project in the current pool") %}
    IQfPool.add_project(contract_address=contract_address, owner=PROJECT_OWNER, ipfs_link_len=link_len, ipfs_link=link)

    return ()
end
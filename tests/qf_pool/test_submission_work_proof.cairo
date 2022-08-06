%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc
from tests.qf_pool.utils.IQfPool import IQfPool

const ERC20_ADDR = 353534
const OWNER_ADDRESS = 123456
const VOTE_TIME_START = 1659279600
const VOTE_TIME_END = 1661785200
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

func add_project{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }(owner: felt):
    tempvar contract_address
    %{
        ids.contract_address = context.contract_address
    %}

    let link_len = 1
    let (link_add_project) = alloc()
    assert link_add_project[0] = 'a'

    IQfPool.add_project(contract_address=contract_address, owner=owner, ipfs_link_len=link_len, ipfs_link=link_add_project)

    return ()
end

@view
func test_cannot_submit_by_non_owner{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }():

    tempvar contract_address
    %{
        ids.contract_address = context.contract_address
        expect_revert(error_message="Ownable: caller is not the owner")
    %}

    let (ipfs) = alloc()
    assert ipfs[0] = 'a'

    IQfPool.submit_work_proof(contract_address=contract_address, project_owner=0, ipfs_len=1, ipfs=ipfs)

    return ()
end

@view
func test_cannot_submit_when_owner_has_no_project{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }():

    tempvar contract_address
    %{
        ids.contract_address = context.contract_address
        stop_prank_callable = start_prank(ids.OWNER_ADDRESS, target_contract_address=ids.contract_address)
        expect_revert(error_message="Owner has no project")
    %}

    let (ipfs) = alloc()
    assert ipfs[0] = 'a'

    IQfPool.submit_work_proof(contract_address=contract_address, project_owner=1234, ipfs_len=1, ipfs=ipfs)

    %{
        stop_prank_callable()
    %}
    return ()
end

@view
func test_submit_work_proof{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }():
    alloc_locals
    tempvar contract_address
    %{
        ids.contract_address = context.contract_address
        stop_prank_callable = start_prank(ids.OWNER_ADDRESS, target_contract_address=ids.contract_address)
    %}
    local contract_address = contract_address

    add_project(PROJECT_OWNER)

    const PROJECT_ID = 1
    let ipfs_len = 4
    let (ipfs) = alloc()
    assert ipfs[0] = 'a'
    assert ipfs[1] = 'b'
    assert ipfs[2] = 'c'
    assert ipfs[3] = 'd'

    let (project_verification_before) = IQfPool.get_project_verification(contract_address=contract_address, project_id=PROJECT_ID)
    assert project_verification_before.submission_ipfs_link_len = 0
    assert project_verification_before.admin_latest_approved_percentage = 0
    assert project_verification_before.is_approved_latest_submission = 0

    # submit work
    %{ expect_events({"name": "project_verification_submission", "data": [ids.PROJECT_ID]}) %}
    IQfPool.submit_work_proof(contract_address=contract_address, project_owner=PROJECT_OWNER, ipfs_len=ipfs_len, ipfs=ipfs)

    let (project_verification_after) = IQfPool.get_project_verification(contract_address=contract_address, project_id=PROJECT_ID)
    assert project_verification_after.submission_ipfs_link_len = ipfs_len
    assert project_verification_after.admin_latest_approved_percentage = 0
    assert project_verification_after.is_approved_latest_submission = 0

    let (ipfs_res) = alloc()
    let (submission_ipfs_len, submission_ipfs) = IQfPool.get_project_verification_ipfs(
                                    contract_address=contract_address,
                                    project_id=PROJECT_ID,
                                    current_index=0,
                                    ipfs_len=ipfs_len,
                                    link_len=0,
                                    link=ipfs_res
                                    )

    assert submission_ipfs_len = ipfs_len
    assert submission_ipfs[0] = 'a'
    assert submission_ipfs[1] = 'b'
    assert submission_ipfs[2] = 'c'
    assert submission_ipfs[3] = 'd'

    %{
        stop_prank_callable()
    %}
    return ()
end

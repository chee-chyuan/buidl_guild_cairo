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
func test_cannot_approve_by_non_owner{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }():

    tempvar contract_address
    %{
        ids.contract_address=context.contract_address
    %}
    const PROJECT_ID = 1

    %{ expect_revert(error_message="Ownable: caller is not the owner") %}
    IQfPool.admin_verify_work(contract_address=contract_address, project_id=PROJECT_ID, approved_percentage=100)

    return ()
end

# percentage must be within range
@view
func test_percentage_within_range{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }():

    tempvar contract_address
    %{
        ids.contract_address=context.contract_address
        stop_prank_callable = start_prank(ids.OWNER_ADDRESS, target_contract_address=ids.contract_address)
    %}

    %{ expect_revert(error_message="Percentage not within range") %}
    IQfPool.admin_verify_work(contract_address=contract_address, project_id=1, approved_percentage=101)

    %{
        stop_prank_callable()
    %}

    return ()
end

# project must exist
@view 
func test_cannot_approve_for_nonexistant_project_id{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }():

    tempvar contract_address
    %{
        ids.contract_address=context.contract_address
        stop_prank_callable = start_prank(ids.OWNER_ADDRESS, target_contract_address=ids.contract_address)
    %}

    %{ expect_revert(error_message="Project does not exist") %}
    IQfPool.admin_verify_work(contract_address=contract_address, project_id=1, approved_percentage=99)

    %{
        stop_prank_callable()
    %}
    return ()
end

# check approve
@view
func test_can_admin_verify_work{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }():
    alloc_locals

    tempvar contract_address
    %{
        ids.contract_address=context.contract_address
        stop_prank_callable = start_prank(ids.OWNER_ADDRESS, target_contract_address=ids.contract_address)
    %}
    local contract_address = contract_address
    add_project(owner=PROJECT_OWNER)
    const PROJECT_ID = 1

    let (project_verification_before) = IQfPool.get_project_verification(contract_address=contract_address, project_id=PROJECT_ID)
    assert project_verification_before.admin_latest_approved_percentage = 0
    IQfPool.admin_verify_work(contract_address=contract_address, project_id=PROJECT_ID, approved_percentage=99)

    let (project_verification_after) = IQfPool.get_project_verification(contract_address=contract_address, project_id=PROJECT_ID)
    assert project_verification_after.admin_latest_approved_percentage = 99
    assert project_verification_after.is_approved_latest_submission = 1

    return ()
end
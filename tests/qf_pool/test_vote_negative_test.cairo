%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256
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

#cannot vote for project id = 0
@view
func test_cannot_vote_for_project_id_zero{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }():

    tempvar contract_address
    %{
        ids.contract_address = context.contract_address
        stop_warp = warp(ids.VOTE_TIME_START + 1, target_contract_address=ids.contract_address) 
        stop_prank_callable = start_prank(ids.OWNER_ADDRESS, target_contract_address=ids.contract_address)
    %}

    tempvar contract_address
    %{
        ids.contract_address = context.contract_address
        expect_revert(error_message="Project id cannot be zero")
    %}
    IQfPool.vote(contract_address=contract_address, project_id=0, amount=Uint256(1,0), voter_addr=1)

    %{
        stop_warp()
        stop_prank_callable()
    %}

    return ()
end

# cannot vote for non existing project
@view
func test_cannot_vote_non_existing_project{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }():

    tempvar contract_address
    %{
        ids.contract_address = context.contract_address
        stop_warp = warp(ids.VOTE_TIME_START + 1, target_contract_address=ids.contract_address) 
        stop_prank_callable = start_prank(ids.OWNER_ADDRESS, target_contract_address=ids.contract_address)
    %}

    tempvar contract_address
    %{
        ids.contract_address = context.contract_address
        expect_revert(error_message="Project does not exist")
    %}
    IQfPool.vote(contract_address=contract_address, project_id=1, amount=Uint256(1,0), voter_addr=1)

    %{
        stop_warp()
        stop_prank_callable()
    %}


    return ()
end

# cannot vote for time that is before vote start
@view
func test_cannot_vote_time_before_vote_start{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }():

    tempvar contract_address
    %{
        ids.contract_address = context.contract_address
        stop_warp = warp(ids.VOTE_TIME_START-1, target_contract_address=ids.contract_address) 
        stop_prank_callable = start_prank(ids.OWNER_ADDRESS, target_contract_address=ids.contract_address)
        expect_revert(error_message="Cannot vote before vote time")
    %}

    # add_project()

    IQfPool.vote(contract_address=contract_address, project_id=0, amount=Uint256(1,0), voter_addr=1)

    %{
        stop_warp()
        stop_prank_callable()
    %}

    return ()
end

# cannot vote for time that is after vote end
@view
func test_cannot_vote_time_after_vote_end{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }():

    tempvar contract_address
    %{
        ids.contract_address = context.contract_address
        stop_warp = warp(ids.VOTE_TIME_END+1, target_contract_address=ids.contract_address) 
        stop_prank_callable = start_prank(ids.OWNER_ADDRESS, target_contract_address=ids.contract_address)
        expect_revert(error_message="Cannot vote after vote time")
    %}

    # add_project()
    IQfPool.vote(contract_address=contract_address, project_id=0, amount=Uint256(1,0), voter_addr=1)

    %{
        stop_warp()
        stop_prank_callable()
    %}

    return ()
end

# cannot vote by non owner
@view
func test_cannot_vote_by_non_owner{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }():

    tempvar contract_address
    %{
        ids.contract_address = context.contract_address
        stop_warp = warp(ids.VOTE_TIME_END+1, target_contract_address=ids.contract_address) 
        expect_revert(error_message="Ownable: caller is not the owner")
    %}  
        # add_project()
        IQfPool.vote(contract_address=contract_address, project_id=0, amount=Uint256(1,0), voter_addr=1)
    %{
        stop_warp()
    %}

    return ()
end
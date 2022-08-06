%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc
from tests.qf_pool.utils.IQfPool import IQfPool
from starkware.cairo.common.uint256 import Uint256, uint256_eq, uint256_sqrt

const ERC20_ADDR = 353534
const OWNER_ADDRESS = 123456
const VOTE_TIME_START = 1659279600
const VOTE_TIME_END = 1661785200
const STREAM_TIME_START = 3
const STREAM_TIME_END = 4

const PROJECT_OWNER = 353232
const PROJECT_OWNER2 = 342232342323
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
    let (link) = alloc()
    assert link[0] = 'a'

    IQfPool.add_project(contract_address=contract_address, owner=owner, ipfs_link_len=link_len, ipfs_link=link)

    return ()
end

# check vote result for new voter to the project
@view
func test_vote_result_new_voter{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }():
    alloc_locals
    local syscall_ptr_temp: felt*
    syscall_ptr_temp = syscall_ptr

    local contract_address_local: felt

    tempvar contract_address
    %{
        ids.contract_address = context.contract_address
        stop_warp = warp(ids.VOTE_TIME_START + 1, target_contract_address=ids.contract_address) 
        stop_prank_callable = start_prank(ids.OWNER_ADDRESS, target_contract_address=ids.contract_address)
    %}
    contract_address_local = contract_address

    let (total_divisor_before) = IQfPool.get_total_divisor(contract_address=contract_address_local)
    let (is_total_divisor_before_zero) = uint256_eq(Uint256(0,0), total_divisor_before)
    assert is_total_divisor_before_zero = 1

    let (total_project_contributed_fund_before) = IQfPool.get_total_project_contributed_fund(contract_address=contract_address_local)
    let (is_total_project_contributed_fund_before_zero) = uint256_eq(Uint256(0,0), total_project_contributed_fund_before)
    assert is_total_project_contributed_fund_before_zero = 1

    add_project(PROJECT_OWNER) # id = 1
    add_project(PROJECT_OWNER2) # id = 2

    # first user voted with 5
    # second user voted with 105

    # first user vote
    IQfPool.vote(contract_address=contract_address_local, project_id=1, amount=Uint256(5,0), voter_addr=1)

    # check project_vote
    let (project_vote) = IQfPool.get_project_vote(contract_address=contract_address_local, project_id=1, voter_addr=1)
    let (is_project_vote_c_equal) = uint256_eq(Uint256(5,0), project_vote.c)
    assert is_project_vote_c_equal = 1

    let sqrt_five = Uint256(2,0) # precision are rounded down
    let (is_project_vote_sqrt_c_equal) = uint256_eq(sqrt_five, project_vote.c_sqrt)
    assert is_project_vote_sqrt_c_equal = 1

    # check project_accumulator
    let (project_accumulator) = IQfPool.get_project_accumulator(contract_address=contract_address_local, project_id=1)
    let (is_sum_c_equal) = uint256_eq(Uint256(5,0), project_accumulator.sum_c)
    assert is_sum_c_equal = 1

    let (is_sum_c_sqrt_equal) = uint256_eq(sqrt_five, project_accumulator.sum_c_sqrt)
    assert is_sum_c_sqrt_equal = 1

    let (is_square_sum_c_sqrt_equal) = uint256_eq(Uint256(4,0), project_accumulator.square_sum_c_sqrt)
    assert is_square_sum_c_sqrt_equal = 1

    # check total_divisor
    let (total_divisor_after) = IQfPool.get_total_divisor(contract_address=contract_address_local)
    let (is_total_divisor_after) = uint256_eq(Uint256(4,0), total_divisor_after)
    assert is_total_divisor_after = 1

    # check total_project_contributed_fund
    let (total_project_contributed_fund_after) = IQfPool.get_total_project_contributed_fund(contract_address=contract_address_local)
    let (is_total_project_contributed_fund_after) = uint256_eq(Uint256(5,0), total_project_contributed_fund_after)
    assert is_total_project_contributed_fund_after = 1


    # check project_vote, second user vote
    const USER_TWO = 2
    IQfPool.vote(contract_address=contract_address_local, project_id=1, amount=Uint256(105,0), voter_addr=USER_TWO)

    # check project_vote
    let (project_vote) = IQfPool.get_project_vote(contract_address=contract_address_local, project_id=1, voter_addr=USER_TWO)
    
    let (is_project_vote_c_equal) = uint256_eq(Uint256(105,0), project_vote.c)
    assert is_project_vote_c_equal = 1

    let sqrt_one_oh_five = Uint256(10,0)
    let (is_project_vote_sqrt_c_equal) = uint256_eq(sqrt_one_oh_five, project_vote.c_sqrt)
    assert is_project_vote_sqrt_c_equal = 1

    # check project_accumulator
    let (project_accumulator) = IQfPool.get_project_accumulator(contract_address=contract_address_local, project_id=1)
    
    let (is_sum_c_equal) = uint256_eq(Uint256(110,0), project_accumulator.sum_c)
    assert is_sum_c_equal = 1

    let sqrt_five_plus_one_oh_five = Uint256(12,0)
    let (is_sum_c_sqrt_equal) = uint256_eq(sqrt_five_plus_one_oh_five, project_accumulator.sum_c_sqrt)
    assert is_sum_c_sqrt_equal = 1

    let (is_square_sum_c_sqrt_equal) = uint256_eq(Uint256(144,0), project_accumulator.square_sum_c_sqrt)
    assert is_square_sum_c_sqrt_equal = 1

    # check total_divisor
    let (total_divisor_after) = IQfPool.get_total_divisor(contract_address=contract_address_local)
    let (is_total_divisor_after) = uint256_eq(Uint256(144,0), total_divisor_after)
    assert is_total_divisor_after = 1

    # check total_project_contributed_fund
    let (total_project_contributed_fund_after) = IQfPool.get_total_project_contributed_fund(contract_address=contract_address_local)
    let (is_total_project_contributed_fund_after) = uint256_eq(Uint256(110,0), total_project_contributed_fund_after)
    assert is_total_project_contributed_fund_after = 1

    ## user 1 voter for project id = 2
    IQfPool.vote(contract_address=contract_address_local, project_id=2, amount=Uint256(5,0), voter_addr=1)

    let (total_divisor_after) = IQfPool.get_total_divisor(contract_address=contract_address_local)
    let (is_total_divisor_after) = uint256_eq(Uint256(148,0), total_divisor_after)
    assert is_total_divisor_after = 1

    let (total_project_contributed_fund_after) = IQfPool.get_total_project_contributed_fund(contract_address=contract_address_local)
    let (is_total_project_contributed_fund_after) = uint256_eq(Uint256(115,0), total_project_contributed_fund_after)
    assert is_total_project_contributed_fund_after = 1


    %{
        stop_warp()
        stop_prank_callable()
    %}
    return ()
end

# check vote result for same voter to the project
@view 
func test_vote_result_repeat_voter{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }():
    alloc_locals
    local syscall_ptr_temp: felt*
    syscall_ptr_temp = syscall_ptr

    local contract_address_local: felt

    tempvar contract_address
    %{
        ids.contract_address = context.contract_address
        stop_warp = warp(ids.VOTE_TIME_START + 1, target_contract_address=ids.contract_address) 
        stop_prank_callable = start_prank(ids.OWNER_ADDRESS, target_contract_address=ids.contract_address)
    %}
    contract_address_local = contract_address

    add_project(PROJECT_OWNER)

    # user add 5 to project id = 1
    # same user add 45 to project id = 1

    # first vote
    IQfPool.vote(contract_address=contract_address_local, project_id=1, amount=Uint256(5,0), voter_addr=1)

    # check project_vote
    let (project_vote) = IQfPool.get_project_vote(contract_address=contract_address_local, project_id=1, voter_addr=1)
    let (is_project_vote_c_equal) = uint256_eq(Uint256(5,0), project_vote.c)
    assert is_project_vote_c_equal = 1

    let sqrt_five = Uint256(2,0) # precision are rounded down
    let (is_project_vote_sqrt_c_equal) = uint256_eq(sqrt_five, project_vote.c_sqrt)
    assert is_project_vote_sqrt_c_equal = 1

    # check project_accumulator
    let (project_accumulator) = IQfPool.get_project_accumulator(contract_address=contract_address_local, project_id=1)
    let (is_sum_c_equal) = uint256_eq(Uint256(5,0), project_accumulator.sum_c)
    assert is_sum_c_equal = 1

    let (is_sum_c_sqrt_equal) = uint256_eq(sqrt_five, project_accumulator.sum_c_sqrt)
    assert is_sum_c_sqrt_equal = 1

    let (is_square_sum_c_sqrt_equal) = uint256_eq(Uint256(4,0), project_accumulator.square_sum_c_sqrt)
    assert is_square_sum_c_sqrt_equal = 1

    let (total_divisor_after) = IQfPool.get_total_divisor(contract_address=contract_address_local)
    let (is_total_divisor_after) = uint256_eq(Uint256(4,0), total_divisor_after)
    assert is_total_divisor_after = 1

    # check total_project_contributed_fund
    let (total_project_contributed_fund_after) = IQfPool.get_total_project_contributed_fund(contract_address=contract_address_local)
    let (is_total_project_contributed_fund_after) = uint256_eq(Uint256(5,0), total_project_contributed_fund_after)
    assert is_total_project_contributed_fund_after = 1

    # second vote
    IQfPool.vote(contract_address=contract_address_local, project_id=1, amount=Uint256(45,0), voter_addr=1)

    # check project_vote
    let (project_vote) = IQfPool.get_project_vote(contract_address=contract_address_local, project_id=1, voter_addr=1)
    let (is_project_vote_c_equal) = uint256_eq(Uint256(50,0), project_vote.c)
    assert is_project_vote_c_equal = 1

    let sqrt_fifty = Uint256(7,0) # precision are rounded down
    let (is_project_vote_sqrt_c_equal) = uint256_eq(sqrt_fifty, project_vote.c_sqrt)
    assert is_project_vote_sqrt_c_equal = 1

    # check project_accumulator
    let (project_accumulator) = IQfPool.get_project_accumulator(contract_address=contract_address_local, project_id=1)
    let (is_sum_c_equal) = uint256_eq(Uint256(50,0), project_accumulator.sum_c)
    assert is_sum_c_equal = 1

    let (is_sum_c_sqrt_equal) = uint256_eq(sqrt_fifty, project_accumulator.sum_c_sqrt)
    assert is_sum_c_sqrt_equal = 1

    let (is_square_sum_c_sqrt_equal) = uint256_eq(Uint256(49,0), project_accumulator.square_sum_c_sqrt)
    assert is_square_sum_c_sqrt_equal = 1

    let (total_divisor_after) = IQfPool.get_total_divisor(contract_address=contract_address_local)
    let (is_total_divisor_after) = uint256_eq(Uint256(49,0), total_divisor_after)
    assert is_total_divisor_after = 1

    # check total_project_contributed_fund
    let (total_project_contributed_fund_after) = IQfPool.get_total_project_contributed_fund(contract_address=contract_address_local)
    let (is_total_project_contributed_fund_after) = uint256_eq(Uint256(50,0), total_project_contributed_fund_after)
    assert is_total_project_contributed_fund_after = 1

    %{
        stop_warp()
        stop_prank_callable()
    %}
    return ()
end
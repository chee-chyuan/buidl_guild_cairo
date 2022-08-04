%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from tests.qf_pool.utils.IQfPool import IQfPool
from starkware.cairo.common.uint256 import Uint256, uint256_eq
from openzeppelin.token.erc20.IERC20 import IERC20

const ERC20_ADDR = 353534
const OWNER_ADDRESS = 123456
const VOTE_TIME_START = 1
const VOTE_TIME_END = 2
const STREAM_TIME_START = 3
const STREAM_TIME_END = 4

@view
func __setup__():
    tempvar erc20_address
    %{
         context.erc20_address = deploy_contract(
            "./src/MockErc20.cairo",
            [1111,
             1111,
             18,
             1000000,1000000,
             ids.OWNER_ADDRESS]
            ).contract_address

         ids.erc20_address = context.erc20_address

         context.contract_address = deploy_contract(
            "./src/qf_pool.cairo", 
            [ids.erc20_address,
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
func test_init_constructor_correctly{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }():
    tempvar contract_address
    tempvar erc20_address
    %{
        ids.contract_address = context.contract_address
        ids.erc20_address = context.erc20_address
    %}

    let (erc20) = IQfPool.get_erc20_addr(contract_address=contract_address)
    assert erc20 = erc20_address

    let (vote_start) = IQfPool.get_vote_start_time(contract_address=contract_address)
    assert vote_start = VOTE_TIME_START

    let (vote_end) = IQfPool.get_vote_end_time(contract_address=contract_address)
    assert vote_end = VOTE_TIME_END

    let (stream_start) = IQfPool.get_stream_start_time(contract_address=contract_address)
    assert stream_start = STREAM_TIME_START

    let (stream_end) = IQfPool.get_stream_end_time(contract_address=contract_address)
    assert stream_end = STREAM_TIME_END

    return ()
end

@view
func test_init_matched_pool{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }():
    alloc_locals
    local syscall_ptr_temp: felt*
    assert syscall_ptr_temp = syscall_ptr
    tempvar erc20_address
    tempvar contract_address
    tempvar syscall_ptr2 = syscall_ptr

    %{
        ids.erc20_address = context.erc20_address
        ids.contract_address = context.contract_address
    %}

    # using locals cos of revoked reference ==
    local erc20_address_local: felt
    erc20_address_local = erc20_address

    local contract_address_local: felt
    contract_address_local = contract_address

    # total matched fund before
    let (matched_before) = IQfPool.get_total_match(contract_address=contract_address_local)
    let (is_matched_before) = uint256_eq(matched_before, Uint256(0,0))
    assert is_matched_before = 1

    # owner transfer funds to pool
    %{
        stop_prank_callable = start_prank(ids.OWNER_ADDRESS, target_contract_address=ids.erc20_address_local)
    %}
    IERC20.transfer(contract_address=erc20_address_local, recipient=contract_address_local, amount=Uint256(5,0))
    %{ stop_prank_callable() %}

    # init the matched fund
    IQfPool.init_matched_pool(contract_address=contract_address_local)
    let (matched_after) = IQfPool.get_total_match(contract_address=contract_address_local)

    # %{
    #     print(f"low: {ids.matched_after.low}")
    #     print(f"high: {ids.matched_after.high}")
    # %}

    let (is_matched_after) = uint256_eq(matched_after, Uint256(5,0))
    assert is_matched_after = 1

    return ()
end

@view 
func test_can_only_init_once{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }():
    tempvar contract_address
    %{
        ids.contract_address = context.contract_address
    %}

    IQfPool.init_matched_pool(contract_address=contract_address)

    # fail if we try to init again
    %{ expect_revert(error_message="Has been initialized") %}
    IQfPool.init_matched_pool(contract_address=contract_address)

    return ()
end

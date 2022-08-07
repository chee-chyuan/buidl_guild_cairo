%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.uint256 import Uint256
from tests.qf_pool.utils.IQfPool import IQfPool
from openzeppelin.token.erc20.IERC20 import IERC20

const OWNER_ADDRESS = 123456
const VOTE_TIME_START = 1
const VOTE_TIME_END = 2
const STREAM_TIME_START = 3
const STREAM_TIME_END = 4

const PROJECT_OWNER = 353232
const PROJECT_OWNER2 = 43234

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
func test_qf_formula{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }():
    alloc_locals
    tempvar contract_address
    tempvar erc20_address
    %{
        ids.contract_address = context.contract_address
        ids.erc20_address = context.erc20_address
        stop_warp = warp(ids.VOTE_TIME_START + 1, target_contract_address=ids.contract_address) 
        stop_prank_callable = start_prank(ids.OWNER_ADDRESS, target_contract_address=ids.contract_address)
        stop_prank_callable_erc20 = start_prank(ids.OWNER_ADDRESS, target_contract_address=ids.erc20_address)
    %}
    local contract_address = contract_address
    local erc20_address = erc20_address

    IERC20.transfer(contract_address=erc20_address, recipient=contract_address, amount=Uint256(1000,0))
    IQfPool.init_matched_pool(contract_address=contract_address)

    const PROJECT_ID_1 = 1
    const PROJECT_ID_2 = 2
    add_project(owner=PROJECT_OWNER)
    add_project(owner=PROJECT_OWNER2)

    const VOTER_ADDRESS = 543214123
    const VOTER_ADDRESS2 = 5432141231
    IQfPool.vote(contract_address=contract_address, project_id=PROJECT_ID_1, amount=Uint256(100,0), voter_addr=VOTER_ADDRESS)
    IQfPool.vote(contract_address=contract_address, project_id=PROJECT_ID_2, amount=Uint256(4,0), voter_addr=VOTER_ADDRESS)
    IQfPool.vote(contract_address=contract_address, project_id=PROJECT_ID_2, amount=Uint256(4,0), voter_addr=VOTER_ADDRESS)
    IQfPool.vote(contract_address=contract_address, project_id=PROJECT_ID_2, amount=Uint256(4,0), voter_addr=VOTER_ADDRESS2)
    let (xx) = IQfPool.get_matched_for_project(contract_address=contract_address, project_id=PROJECT_ID_1)
    let (yy) = IQfPool.get_matched_for_project(contract_address=contract_address, project_id=PROJECT_ID_2)

    let (accumulator) = IQfPool.get_project_accumulator(contract_address=contract_address,project_id=PROJECT_ID_1)
    let (divisor) = IQfPool.get_total_divisor(contract_address=contract_address)
    let (matched) = IQfPool.get_total_match(contract_address=contract_address)

    %{
        print(f"accumulator.sum_c.low: {ids.accumulator.sum_c.low}")
        print(f"accumulator.sum_c.high: {ids.accumulator.sum_c.high}")

        print(f"accumulator.sum_c_sqrt.low: {ids.accumulator.sum_c_sqrt.low}")
        print(f"accumulator.sum_c_sqrt.high: {ids.accumulator.sum_c_sqrt.high}")

        print(f"accumulator.square_sum_c_sqrt.low: {ids.accumulator.square_sum_c_sqrt.low}")
        print(f"accumulator.square_sum_c_sqrt.high: {ids.accumulator.square_sum_c_sqrt.high}")

        print(f"divisor.low: {ids.divisor.low}")
        print(f"divisor.high: {ids.divisor.high}")

        print(f"matched.low: {ids.matched.low}")
        print(f"matched.high: {ids.matched.high}")
    %}

    %{
        print(f"xx.low: {ids.xx.low}")
        print(f"xx.high: {ids.xx.high}")
        print(f"yy.low: {ids.yy.low}")
        print(f"yy.high: {ids.yy.high}")
    %}

    %{
        stop_warp()
        stop_prank_callable()
        stop_prank_callable_erc20()
    %}
    return ()
end
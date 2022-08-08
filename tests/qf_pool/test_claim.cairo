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
func test_claim{
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

    return ()
end
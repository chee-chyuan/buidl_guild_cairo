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
    tempvar contract_address
    %{
        ids.contract_address = context.contract_address
    %}

    let link_len = 3
    let (link) = alloc()
    assert link[0] = 'a'
    assert link[1] = 'b'
    assert link[2] = 'c'

    let (current_id_before) = IQfPool.get_current_project_id(contract_address=contract_address)
    assert current_id_before = 0

    IQfPool.add_project(contract_address=contract_address, owner=PROJECT_OWNER, ipfs_link_len=link_len, ipfs_link=link)

    # revoked reference ==, and im too lazy to use local
    tempvar contract_address
    %{
        ids.contract_address = context.contract_address
    %}

    let (current_id_after) = IQfPool.get_current_project_id(contract_address=contract_address)
    assert current_id_after = 1

    let (ipfs_link) = alloc()

    let (ipfs_link_len, ipfs_link) = IQfPool.get_project_ipfs_link(
                                        contract_address=contract_address,
                                        project_id=0,
                                        current_index=0,
                                        ipfs_len=link_len,
                                        link_len=0,
                                        link=ipfs_link
                                        )

    assert ipfs_link_len = link_len
    assert ipfs_link[0] = 'a'
    assert ipfs_link[1] = 'b'
    assert ipfs_link[2] = 'c'

    return ()
end
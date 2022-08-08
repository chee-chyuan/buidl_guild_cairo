%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from tests.qf_pool.utils.IQfPool import IQfPool
from starkware.starknet.common.syscalls import get_block_timestamp

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

@view
func test_get_time_as_percentage{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
}():
    let start_time = 1650000000
    let end_time = 1660000000
    tempvar contract_address
    %{
        ids.contract_address = context.contract_address
        stop_warp = warp(ids.start_time + 1000000, target_contract_address=ids.contract_address) 
    %}
    let (percentage) = IQfPool.get_time_as_percentage(
                                                        contract_address=contract_address, 
                                                        start_time=start_time, 
                                                        end_time=end_time
                                                        )

    %{
        print(f"percentage: {ids.percentage.low}")

        stop_warp()
    %}
    return ()
end

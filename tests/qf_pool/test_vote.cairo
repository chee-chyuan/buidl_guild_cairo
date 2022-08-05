%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
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

# check vote result for new voter to the project
@view
func test_vote_result_new_voter{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }():
    tempvar contract_address
    %{
        ids.contract_address=context.contract_address
    %}

    let (total_project_contributed_fund_before) = IQfPool.get_total_project_contributed_fund(contract_address=contract_address)

    return ()
end

# check vote result for same voter to the project
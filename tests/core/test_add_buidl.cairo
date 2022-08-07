%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc
from tests.core.utils.ICore import ICore

const CONTRACT_HASH = 353534
@view
func __setup__():
    tempvar user_registry_address
    %{
         context.user_registry = deploy_contract(
            "./src/user_registry.cairo", 
            []).contract_address

         ids.user_registry_address = context.user_registry

         context.contract_address = deploy_contract(
            "./src/core.cairo", 
            [ids.CONTRACT_HASH,
             ids.user_registry_address
            ]).contract_address
    %}
    return ()
end

@view
func test_fail_to_add_user_not_registered{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
}():
    tempvar contract_address
    %{
        ids.contract_address = context.contract_address
    %}

    let ipfs_len = 1
    let (ipfs) = alloc()
    assert ipfs[0] = 'a'

    %{ expect_revert(error_message="User not registered") %}
    ICore.add_buidl(contract_address=contract_address, ipfs_len=1, ipfs=ipfs)

    return ()
end

# @view
# func test_add_buidl{
#     syscall_ptr : felt*,
#     pedersen_ptr : HashBuiltin*,
#     range_check_ptr,
# }():
#     return ()
# end
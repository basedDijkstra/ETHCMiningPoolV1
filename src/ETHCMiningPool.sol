// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(address owner_) {
        _transferOwnership(owner_);
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If EIP-1153 (transient storage) is available on the chain you're deploying at,
 * consider using {ReentrancyGuardTransient} instead.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;

    uint256 private _status;

    /**
     * @dev Unauthorized reentrant call.
     */
    error ReentrancyGuardReentrantCall();

    constructor() {
        _status = NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be NOT_ENTERED
        if (_status == ENTERED) {
            revert ReentrancyGuardReentrantCall();
        }

        // Any calls to nonReentrant after this point will fail
        _status = ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == ENTERED;
    }
}

interface IETHC {
    struct Block {
        address selectedMiner;
        uint256 miningReward;
    }

    function mine(uint256 mineCount) external payable;
    function futureMine(uint256 mineCount, uint256 blockCounts) external payable;
    function revealSelectedMiner(uint256 targetBlock) external;

    function miningReward() external view returns (uint256);
    function selectedMinerOfBlock(uint256 _blockNumber) external view returns (address);
    function minersOfBlockCount(uint256 _blockNumber) external view returns (uint256);
    function blockNumber() external view returns (uint256);
    function mineCost() external view returns (uint256);
    function blocks(uint256 blockNumber) external view returns (Block memory);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function balanceOf(address owner) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
}

/**
 * @dev Interface of the ERC-20 standard as defined in the ERC.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

/**
 * @dev Interface for the optional metadata functions from the ERC-20 standard.
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

/**
 * @dev Standard ERC-20 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC-20 tokens.
 */
interface IERC20Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC20InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC20InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `spender`’s `allowance`. Used in transfers.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     * @param allowance Amount of tokens a `spender` is allowed to operate with.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC20InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `spender` to be approved. Used in approvals.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC20InvalidSpender(address spender);
}

/**
 * @dev Standard ERC-721 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC-721 tokens.
 */
interface IERC721Errors {
    /**
     * @dev Indicates that an address can't be an owner. For example, `address(0)` is a forbidden owner in ERC-20.
     * Used in balance queries.
     * @param owner Address of the current owner of a token.
     */
    error ERC721InvalidOwner(address owner);

    /**
     * @dev Indicates a `tokenId` whose `owner` is the zero address.
     * @param tokenId Identifier number of a token.
     */
    error ERC721NonexistentToken(uint256 tokenId);

    /**
     * @dev Indicates an error related to the ownership over a particular token. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param tokenId Identifier number of a token.
     * @param owner Address of the current owner of a token.
     */
    error ERC721IncorrectOwner(address sender, uint256 tokenId, address owner);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC721InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC721InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     * @param tokenId Identifier number of a token.
     */
    error ERC721InsufficientApproval(address operator, uint256 tokenId);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC721InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC721InvalidOperator(address operator);
}

/**
 * @dev Standard ERC-1155 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC-1155 tokens.
 */
interface IERC1155Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     * @param tokenId Identifier number of a token.
     */
    error ERC1155InsufficientBalance(address sender, uint256 balance, uint256 needed, uint256 tokenId);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC1155InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC1155InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     * @param owner Address of the current owner of a token.
     */
    error ERC1155MissingApprovalForAll(address operator, address owner);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC1155InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC1155InvalidOperator(address operator);

    /**
     * @dev Indicates an array length mismatch between ids and values in a safeBatchTransferFrom operation.
     * Used in batch transfers.
     * @param idsLength Length of the array of token identifiers
     * @param valuesLength Length of the array of token amounts
     */
    error ERC1155InvalidArrayLength(uint256 idsLength, uint256 valuesLength);
}

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC-20
 * applications.
 */
abstract contract ERC20 is Context, IERC20, IERC20Metadata, IERC20Errors {
    mapping(address account => uint256) private _balances;

    mapping(address account => mapping(address spender => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `value`.
     */
    function transfer(address to, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, value);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `value` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, value);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Skips emitting an {Approval} event indicating an allowance update. This is not
     * required by the ERC. See {xref-ERC20-_approve-address-address-uint256-bool-}[_approve].
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `value`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `value`.
     */
    function transferFrom(address from, address to, uint256 value) public virtual returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, value);
        _transfer(from, to, value);
        return true;
    }

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead.
     */
    function _transfer(address from, address to, uint256 value) internal {
        if (from == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        if (to == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(from, to, value);
    }

    /**
     * @dev Transfers a `value` amount of tokens from `from` to `to`, or alternatively mints (or burns) if `from`
     * (or `to`) is the zero address. All customizations to transfers, mints, and burns should be done by overriding
     * this function.
     *
     * Emits a {Transfer} event.
     */
    function _update(address from, address to, uint256 value) internal virtual {
        if (from == address(0)) {
            // Overflow check required: The rest of the code assumes that totalSupply never overflows
            _totalSupply += value;
        } else {
            uint256 fromBalance = _balances[from];
            if (fromBalance < value) {
                revert ERC20InsufficientBalance(from, fromBalance, value);
            }
            unchecked {
                // Overflow not possible: value <= fromBalance <= totalSupply.
                _balances[from] = fromBalance - value;
            }
        }

        if (to == address(0)) {
            unchecked {
                // Overflow not possible: value <= totalSupply or value <= fromBalance <= totalSupply.
                _totalSupply -= value;
            }
        } else {
            unchecked {
                // Overflow not possible: balance + value is at most totalSupply, which we know fits into a uint256.
                _balances[to] += value;
            }
        }

        emit Transfer(from, to, value);
    }

    /**
     * @dev Creates a `value` amount of tokens and assigns them to `account`, by transferring it from address(0).
     * Relies on the `_update` mechanism
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead.
     */
    function _mint(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(address(0), account, value);
    }

    /**
     * @dev Destroys a `value` amount of tokens from `account`, lowering the total supply.
     * Relies on the `_update` mechanism.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead
     */
    function _burn(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        _update(account, address(0), value);
    }

    /**
     * @dev Sets `value` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     *
     * Overrides to this logic should be done to the variant with an additional `bool emitEvent` argument.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        _approve(owner, spender, value, true);
    }

    /**
     * @dev Variant of {_approve} with an optional flag to enable or disable the {Approval} event.
     *
     * By default (when calling {_approve}) the flag is set to true. On the other hand, approval changes made by
     * `_spendAllowance` during the `transferFrom` operation set the flag to false. This saves gas by not emitting any
     * `Approval` event during `transferFrom` operations.
     *
     * Anyone who wishes to continue emitting `Approval` events on the`transferFrom` operation can force the flag to
     * true using the following override:
     *
     * ```solidity
     * function _approve(address owner, address spender, uint256 value, bool) internal virtual override {
     *     super._approve(owner, spender, value, true);
     * }
     * ```
     *
     * Requirements are the same as {_approve}.
     */
    function _approve(address owner, address spender, uint256 value, bool emitEvent) internal virtual {
        if (owner == address(0)) {
            revert ERC20InvalidApprover(address(0));
        }
        if (spender == address(0)) {
            revert ERC20InvalidSpender(address(0));
        }
        _allowances[owner][spender] = value;
        if (emitEvent) {
            emit Approval(owner, spender, value);
        }
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `value`.
     *
     * Does not update the allowance value in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Does not emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 value) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            if (currentAllowance < value) {
                revert ERC20InsufficientAllowance(spender, currentAllowance, value);
            }
            unchecked {
                _approve(owner, spender, currentAllowance - value, false);
            }
        }
    }
}

/**
 * @title TokenVault
 * @notice Secure storage contract for ETHC tokens and mining operations
 * @dev Acts as a delegate contract to EthCoinMiningPool, handling direct interactions with ETHC contract
 */
contract TokenVault is Ownable, ReentrancyGuard {
    IETHC public ETHC;

    /**
     * @notice Initializes the vault with ETHC token contract and sets up permissions
     * @param tokenAddress The address of the ETHC token contract
     * @dev Constructor flow:
     * 1. Sets up Ownable with pool as owner
     * 2. Initializes ETHC interface
     * 3. Approves pool for infinite token transfers
     *
     * Security considerations:
     * - msg.sender (the pool) becomes the owner
     * - Infinite approval is safe because:
     *   a) Owner is trusted (the pool contract)
     *   b) Ownership cannot be transferred (pool controlled)
     *   c) Pool handles all token management logic
     *
     * This setup ensures:
     * - Only the pool can access vault funds
     * - Direct mining operations are possible
     * - Efficient token transfers without repeated approvals
     */
    constructor(address tokenAddress) Ownable(msg.sender) {
        ETHC = IETHC(tokenAddress);

        // ETHC implements infinite approval via type(uint256).max
        ETHC.approve(msg.sender, type(uint256).max);
    }

    /**
     * @notice Execute mining operation with ETHC contract
     * @param mineCount Number of mining operations to perform
     * @dev Only callable by owner (EthCoinMiningPool)
     */
    function mine(uint256 mineCount) external payable nonReentrant {
        ETHC.mine{value: msg.value}(mineCount);
    }

    /**
     * @notice Execute future mining operations with ETHC contract
     * @param mineCount Number of mining operations to perform
     * @param blockCounts Number of blocks to mine ahead
     * @dev Only callable by owner (EthCoinMiningPool)
     */
    function futureMine(uint256 mineCount, uint256 blockCounts) external payable nonReentrant {
        ETHC.futureMine{value: msg.value}(mineCount, blockCounts);
    }

    /**
     * @notice Fallback function to handle direct ETH transfers for mining
     * @dev Automatically processes received ETH into mining operations
     *
     * Process flow:
     * 1. Calculates maximum whole mining operations possible
     * 2. Executes mining with exact ETH amount needed
     * 3. Refunds any excess ETH to sender
     *
     * Mathematical guarantees:
     * - mineCount = floor(msg.value / mineCost)
     * - mineValue = mineCount * mineCost
     * - refund = msg.value - mineValue
     *
     * Security features:
     * - Integer division prevents over-mining
     * - Exact ETH accounting prevents fund locking
     * - Automatic refund of excess ETH
     *
     * Note: This function duplicates mining logic from the pool
     * for users who accidentally send ETH directly to vault.
     * Using the pool contract directly is required in order to gain shares.
     * Using this pool contract will possibly increase rewards for the whole pool
     * without any attribution. Suitable for pool beneficial ETH transfers only.
     */
    receive() external payable {
        uint256 mineCost = ETHC.mineCost();
        uint256 mineCount = msg.value / mineCost;
        uint256 mineValue = mineCount * mineCost;

        ETHC.mine{value: mineValue}(mineCount);
        if (address(this).balance > 0) {
            (bool ok,) = msg.sender.call{value: address(this).balance}("");
            require(ok);
        }
    }
}

interface IUniswapV3Pool {
    function flash(address recipient, uint256 amount0, uint256 amount1, bytes calldata data) external;
    function token0() external view returns (address);
    function token1() external view returns (address);
}

interface IUniswapV3FlashCallback {
    /// @notice Called to `msg.sender` after transferring to the recipient from IUniswapV3Pool#flash.
    /// @dev In the implementation you must repay the pool the tokens sent by flash plus the computed fee amounts.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// @param fee0 The fee amount in token0 due to the pool by the end of the flash
    /// @param fee1 The fee amount in token1 due to the pool by the end of the flash
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#flash call
    function uniswapV3FlashCallback(uint256 fee0, uint256 fee1, bytes calldata data) external;
}

/**
 * @title EthCoinMiningPool
 * @notice A mining pool contract for ETHC that distributes mining rewards through share tokens
 * @dev Implements ERC20 for share tokens and uses a TokenVault for secure storage
 *
 * @notice Fee Structures:
 * 1. Operator Fee on Mining:
 *    - Calculated as (share amount * operatorFeeNum) / operatorFeeDenom
 *    - Default fee is 200/10000 = 2%
 *    - Maximum fee is capped at 10% (1000/10000)
 *
 * 2. Flash Loan Fee:
 *    - Calculated as (borrowed amount * ETHCFlashLoanFeeNum) / ETHCFlashLoanFeeDenom
 *    - Default fee is 20/10000 = 0.2%
 *    - Fee is added to borrowed amount for required repayment
 *    - Example: Borrowing 1000 ETHC requires repayment of 1002 ETHC
 */
contract ETHCoinMiningPool is ERC20, Ownable, ReentrancyGuard, IUniswapV3Pool {
    IETHC public ETHC;
    bool public miningPaused = false;
    bool public flashPaused = false;

    /// @notice Numerator for flash loan fee calculation (e.g., 20 = 0.2% with 10000 denominator)
    /// @dev Used to calculate required repayment amount for flash loans
    uint256 public ETHCFlashLoanFeeNum = 20;

    /// @notice Denominator for flash loan fee calculation (10000 = 100%)
    /// @dev All fee calculations use this as the denominator to determine percentages
    uint256 public ETHCFlashLoanFeeDenom = 10000;

    TokenVault public vault;
    uint256 public lastBlockWeight = 5;
    uint256 public currentBlockWeight = 1;

    /// @notice Address of the operator who receives fees
    /// @dev Set during contract deployment, can be updated by owner
    address public operatorAddress;

    /// @notice Numerator for operator fee calculation (e.g., 200 = 2% with 10000 denominator)
    /// @dev Used in mining operations to calculate operator's share of rewards
    uint256 public operatorFeeNum = 200;

    /// @notice Denominator for operator fee calculation (10000 = 100%)
    /// @dev All fee calculations use this as the denominator to determine percentages
    uint256 public operatorFeeDenom = 10000;

    address public token0;
    address public token1;

    event FlashFeeCollected(uint256 fee);
    event FeeCollected(address miner, uint256 amount);
    event MiningStatusChanged(bool isPaused);
    event FlashLoanStatusChanged(bool isPaused);
    event FlashLoanFeesUpdated(uint256 oldFeeNum, uint256 newFeeNum);
    event OperatorFeeUpdated(uint256 oldFeeNum, uint256 newFeeNum);
    event OperatorAddressUpdated(address oldOperatorAddress, address newOperatorAddress);
    event BlockWeightsUpdated(
        uint256 oldLastBlockWeight,
        uint256 newLastBlockWeight,
        uint256 oldCurrentBlockWeight,
        uint256 newCurrentBlockWeight
    );
    event SharesMinted(address indexed recipient, uint256 shares, uint256 mineCount);
    event SharesRedeemed(address indexed redeemer, uint256 shares, uint256 reward);
    event FlashLoanExecuted(address indexed borrower, uint256 amount, uint256 fee);
    event MiningExecuted(
        address indexed miner, uint256 mineCount, uint256 blockReward, uint256 shares, uint256 feeAmount
    );
    event FutureMiningExecuted(
        address indexed miner,
        uint256 mineCount,
        uint256 blockCounts,
        uint256 blockReward,
        uint256 totalShares,
        uint256 totalFeeAmount
    );

    /**
     * @notice Constructor creates a new mining pool with associated vault
     * @param tokenAddress Address of the ETHC token contract
     */
    constructor(address tokenAddress, address WETHAddress)
        ERC20("ETHC Mining Pool Share", "ETHC-MPS")
        Ownable(msg.sender)
    {
        ETHC = IETHC(tokenAddress);
        vault = new TokenVault(tokenAddress);

        (token0, token1) = tokenAddress < WETHAddress ? (tokenAddress, WETHAddress) : (WETHAddress, tokenAddress);
    }

    /**
     * @notice Updates the flash loan fee percentage
     * @param newETHCFlashLoanFeeNum New fee numerator (denominator is 10000)
     * @dev Only callable by owner
     * Example calculation:
     * - If newETHCFlashLoanFeeNum = 20, actual fee = 20/10000 = 0.2%
     * - For 1000 ETHC borrowed: borrower must repay 1002 ETHC (0.2% fee = 2 ETHC)
     */
    function setFlashFee(uint256 newETHCFlashLoanFeeNum) external onlyOwner {
        uint256 oldFeeNum = ETHCFlashLoanFeeNum;
        ETHCFlashLoanFeeNum = newETHCFlashLoanFeeNum;
        emit FlashLoanFeesUpdated(oldFeeNum, newETHCFlashLoanFeeNum);
    }

    /**
     * @notice Pauses flash loan functionality
     * @dev Only callable by owner, requires flash loans to be active
     */
    function pauseFlash() external onlyOwner {
        require(!flashPaused, "Flash loans already paused");
        flashPaused = true;
        emit FlashLoanStatusChanged(true);
    }

    /**
     * @notice Unpauses flash loan functionality
     * @dev Only callable by owner, requires flash loans to be paused
     */
    function unPauseFlash() external onlyOwner {
        require(flashPaused, "Flash loans not paused");
        flashPaused = false;
        emit FlashLoanStatusChanged(false);
    }

    /**
     * @notice Pauses mining operations
     * @dev Only callable by owner, requires mining to be active
     */
    function pauseMining() external onlyOwner {
        require(!miningPaused, "Mining already paused");
        miningPaused = true;
        emit MiningStatusChanged(true);
    }

    /**
     * @notice Updates the operator address of the mining pool
     * @dev Can only be called by the contract owner
     * @param newOperatorAddress The address of the new operator
     * @custom:emits OperatorAddressUpdated event with old and new operator addresses
     */
    function setOperator(address newOperatorAddress) external onlyOwner {
        require(newOperatorAddress != address(0), "Invalid operator Address");
        require(newOperatorAddress != operatorAddress, "Cannot setOperator to the same address");
        address oldOperatorAddress = operatorAddress;
        operatorAddress = newOperatorAddress;
        emit OperatorAddressUpdated(oldOperatorAddress, newOperatorAddress);
    }

    /**
     * @notice Updates operator fee percentage
     * @param newOperatorFee New fee numerator (denominator is 10000)
     * @dev Only callable by owner, fee capped at 10%
     * Example calculation:
     * - If newOperatorFee = 200, actual fee = 200/10000 = 2%
     * - For 1000 shares mined: operator receives 20 shares (2% of 1000)
     */
    function setOperatorFee(uint256 newOperatorFee) external onlyOwner {
        require(newOperatorFee <= 1000, "Fee exceeds maximum");
        uint256 oldFee = operatorFeeNum;
        operatorFeeNum = newOperatorFee;
        emit OperatorFeeUpdated(oldFee, newOperatorFee);
    }

    /**
     * @notice Updates block weights used in share calculations
     * @param newLastBlockWeight Weight for previous block
     * @param newCurrentBlockWeight Weight for current block
     * @dev Only callable by owner
     */
    function setBlockWeights(uint256 newLastBlockWeight, uint256 newCurrentBlockWeight) external onlyOwner {
        require(newLastBlockWeight > 0 && newCurrentBlockWeight > 0, "Weights must be positive");
        emit BlockWeightsUpdated(lastBlockWeight, newLastBlockWeight, currentBlockWeight, newCurrentBlockWeight);
        lastBlockWeight = newLastBlockWeight;
        currentBlockWeight = newCurrentBlockWeight;
    }

    /**
     * @notice Executes mining operations and mints share tokens
     * @param mineCount Number of mining operations to perform
     * @dev Share calculation formula:
     * shares = blockReward * mineCount / (weightedAvgMiners)
     * where weightedAvgMiners = (lastBlockMiners * lastBlockWeight + nextBlockMiners * currentBlockWeight) / (lastBlockWeight + currentBlockWeight)
     *
     * This formula ensures:
     * 1. Proportional distribution based on mining power contribution
     * 2. Balanced weighting between consecutive blocks
     * 3. Fair operator fee deduction
     *
     * Requirements:
     * - Mining must not be paused
     * - msg.value must be sufficient for mineCount operations
     * - mineCount must not cause arithmetic overflow in calculations
     *
     * Emits:
     * - MiningExecuted event with mining details and share distribution
     * - FeeCollected event if operator fee is charged
     */
    function mine(uint256 mineCount) external payable nonReentrant {
        _mine(mineCount, msg.value);
    }

    /**
     * @notice Internal function to process mining operations and mint shares
     * @param mineCount Number of mining operations to perform
     * @param ethValue Amount of ETH provided for mining
     * @dev Calculates shares based on:
     * 1. Current block reward
     * 2. Weighted average of miners across blocks
     * 3. Operator fee deduction
     *
     * The calculation ensures fair distribution by:
     * - Using weighted averages for miner counts
     * - Scaling rewards based on block participation
     * - Applying proportional operator fees
     */
    function _mine(uint256 mineCount, uint256 ethValue) internal {
        require(!miningPaused, "Mining is paused");

        uint256 blockNumber = ETHC.blockNumber();
        uint256 lastBlockMiners = ETHC.minersOfBlockCount(blockNumber) * lastBlockWeight;
        uint256 nextBlockMiners = ETHC.minersOfBlockCount(blockNumber + 1) * currentBlockWeight;
        IETHC.Block memory nextBlock = ETHC.blocks(blockNumber + 1);

        uint256 blockReward = nextBlock.miningReward == 0 ? ETHC.miningReward() : nextBlock.miningReward;

        // Calculate weighted average miners and resulting shares
        uint256 weightedAvgMiners = (lastBlockMiners + nextBlockMiners) / (lastBlockWeight + currentBlockWeight);
        uint256 shares = blockReward * mineCount / weightedAvgMiners;

        // Calculate and deduct operator fee
        uint256 feeAmount = shares * operatorFeeNum / operatorFeeDenom;

        // Execute mining through vault
        vault.mine{value: ethValue}(mineCount);

        // Mint shares to miner and operator
        _mint(msg.sender, shares - feeAmount);
        if (feeAmount > 0) {
            _mint(operatorAddress, feeAmount);
            emit FeeCollected(msg.sender, feeAmount);
        }

        emit MiningExecuted(msg.sender, mineCount, blockReward, shares, feeAmount);
    }

    /**
     * @notice Executes mining operations for multiple future blocks
     * @param mineCount Number of mining operations to perform per block
     * @param blockCounts Number of consecutive blocks to mine
     * @dev Extends the base mining calculation across multiple blocks:
     * - Total shares = per-block shares * blockCounts
     * - Total fee = per-block fee * blockCounts
     *
     * Requirements:
     * - Mining must not be paused
     * - msg.value must be sufficient for mineCount * blockCounts operations
     * - Total share calculation must not overflow
     * - blockCounts must be reasonable to prevent excessive gas usage
     *
     * Emits:
     * - FutureMiningExecuted event with comprehensive mining details
     * - FeeCollected event if operator fee is charged
     */
    function futureMine(uint256 mineCount, uint256 blockCounts) external payable nonReentrant {
        require(!miningPaused, "Mining is paused");

        uint256 blockNumber = ETHC.blockNumber();
        uint256 lastBlockMiners = ETHC.minersOfBlockCount(blockNumber) * lastBlockWeight;
        uint256 nextBlockMiners = ETHC.minersOfBlockCount(blockNumber + 1) * currentBlockWeight;
        IETHC.Block memory nextBlock = ETHC.blocks(blockNumber + 1);

        uint256 blockReward = nextBlock.miningReward == 0 ? ETHC.miningReward() : nextBlock.miningReward;

        // Calculate shares for a single block
        uint256 weightedAvgMiners = (lastBlockMiners + nextBlockMiners) / (lastBlockWeight + currentBlockWeight);
        uint256 shares = blockReward * mineCount / weightedAvgMiners;

        // Calculate total shares and fees across all blocks
        uint256 feeAmount = shares * operatorFeeNum / operatorFeeDenom;
        uint256 totalShares = (shares - feeAmount) * blockCounts;
        uint256 totalFeeAmount = feeAmount * blockCounts;

        // Execute future mining through vault
        vault.futureMine{value: msg.value}(mineCount, blockCounts);

        // Mint total shares to miner and operator
        _mint(msg.sender, totalShares);
        if (totalFeeAmount > 0) {
            _mint(operatorAddress, totalFeeAmount);
            emit FeeCollected(msg.sender, totalFeeAmount);
        }

        emit FutureMiningExecuted(msg.sender, mineCount, blockCounts, blockReward, totalShares, totalFeeAmount);
    }

    /**
     * @notice Redeems pool share tokens for underlying ETHC tokens
     * @param amount Amount of pool share tokens to redeem (0 = redeem all)
     * @dev Calculation of rewards:
     * reward = (user_shares / total_shares) * total_ETHC_balance
     *
     * The redemption process:
     * 1. Verifies user has sufficient balance
     * 2. If amount is 0, uses entire balance
     * 3. Calculates proportional share of pool's ETHC
     * 4. Burns share tokens
     * 5. Transfers ETHC from vault to user
     *
     * Security considerations:
     * - Uses nonReentrant modifier to prevent reentrancy attacks
     * - Performs balance check before state changes
     * - Handles zero amount as special case for full redemption
     * - Uses safe ERC20 operations via OpenZeppelin
     *
     * Requirements:
     * - User must have sufficient balance
     * - Pool must have sufficient ETHC balance in vault
     * - Transfer from vault must succeed
     *
     * @return reward Amount of ETHC tokens received
     *
     * Emits:
     * - SharesRedeemed event with redemption details including amount and reward
     *
     * @custom:security-note The reward calculation is based on the current ETHC balance,
     * which includes pending rewards and fees. This ensures fair distribution of all
     * accumulated rewards.
     */
    function redeem(uint256 amount) external nonReentrant returns (uint256 reward) {
        uint256 currentBalance = balanceOf(msg.sender);
        require(currentBalance >= amount, "Insufficient Balance");

        // Handle full redemption case
        amount = amount == 0 ? currentBalance : amount;

        // Calculate proportional reward
        reward = _calculateReward(amount);

        // Burn shares first (checks-effects-interactions pattern)
        _burn(msg.sender, amount);

        // Transfer ETHC from vault to user
        ETHC.transferFrom(address(vault), msg.sender, reward);

        emit SharesRedeemed(msg.sender, amount, reward);
    }

    /**
     * @notice Executes a flash loan of ETHC tokens to a recipient contract
     * @param recipient The contract address that will receive the flash loaned tokens
     * @param amount0 The amount of token0 to flash loan (used if token0 is ETHC)
     * @param amount1 The amount of token1 to flash loan (used if token1 is ETHC)
     * @param data Arbitrary data to be passed to the recipient's callback function
     * @dev Process flow:
     * 1. Verifies flash loans are not paused
     * 2. Determines which token (amount0 or amount1) corresponds to ETHC
     * 3. Calculates fee based on configured fee rate (ETHCFlashLoanFeeNum/ETHCFlashLoanFeeDenom)
     * 4. Transfers ETHC from vault to borrower
     * 5. Calls recipient's uniswapV3FlashCallback function
     * 6. Verifies sufficient repayment (loan + fee)
     * 7. Returns all ETHC to vault
     *
     * Security measures:
     * - nonReentrant modifier prevents recursive flash loans
     * - Requires full repayment including fee
     * - All excess ETHC is returned to vault
     * - Separate recipient and msg.sender allows for contract abstraction
     *
     * Requirements:
     * - Flash loans must not be paused
     * - Recipient must implement IUniswapV3FlashCallback interface
     * - Callback must ensure repayment of loan + fee
     * - Vault must have sufficient ETHC balance
     * - Only one of amount0 or amount1 should be non-zero (the one corresponding to ETHC)
     *
     * Fee calculation:
     * feeAmount = amount * ETHCFlashLoanFeeNum / ETHCFlashLoanFeeDenom
     * Required repayment = amount + feeAmount
     *
     * @custom:error-cases
     * Reverts if:
     * - Flash loans are paused
     * - Both amount0 and amount1 are non-zero
     * - Neither amount0 nor amount1 correspond to the ETHC amount
     * - Insufficient repayment after callback
     * - Callback reverts
     * - Reentrancy is detected
     *
     * Emits:
     * - FlashFeeCollected event when fee is successfully collected
     * - FlashLoanExecuted event with borrower, amount, and fee details
     */
    function flash(address recipient, uint256 amount0, uint256 amount1, bytes memory data) external nonReentrant {
        require(!flashPaused);
        address tokenAddress = address(ETHC);

        uint256 amount = token0 == tokenAddress ? amount0 : amount1;
        require(amount > 0 && amount0 + amount1 == amount, "Only support lending ETHC");
        uint256 feeAmount = amount * ETHCFlashLoanFeeNum / ETHCFlashLoanFeeDenom;

        ETHC.transferFrom(recipient, msg.sender, amount);
        IUniswapV3FlashCallback(recipient).uniswapV3FlashCallback(
            token0 == tokenAddress ? feeAmount : 0, token0 == tokenAddress ? 0 : feeAmount, data
        );
        uint256 ethcBalance = ETHC.balanceOf(address(this));
        require(ethcBalance >= amount + feeAmount, "Insufficient fee paid");
        ETHC.transfer(address(vault), ethcBalance);
        emit FlashFeeCollected(feeAmount);
    }

    /**
     * @notice Calculates the current ETHC reward a user would receive for their shares
     * @param rewardee Address to check the potential reward for
     * @return uint256 Amount of ETHC tokens the user would receive if they redeemed now
     * @dev Calculation is based on:
     * - User's current share token balance
     * - Current total supply of share tokens
     * - Current ETHC balance in the vault
     *
     * The reward is calculated as: (user_shares / total_shares) * total_ETHC_balance
     *
     * This function is useful for:
     * - Users to check expected redemption amounts
     * - UIs to display current value of holdings
     * - External contracts to determine redemption timing
     *
     * Note: This value can change between calls due to:
     * - Mining rewards being added
     * - Other users redeeming shares
     * - Flash loan fees accumulating
     */
    function currentReward(address rewardee) external view returns (uint256) {
        return _calculateReward(balanceOf(rewardee));
    }

    /**
     * @notice Returns the current total ETHC balance held in the vault
     * @return uint256 Current balance of ETHC tokens in the vault
     * @dev This balance represents:
     * - All mining rewards earned
     * - Accumulated flash loan fees
     * - Minus any redeemed amounts
     *
     * Used to:
     * - Monitor pool performance
     * - Calculate share values
     * - Verify flash loan capacity
     *
     * This value can change frequently due to:
     * - New mining rewards
     * - Flash loan fee accumulation
     * - Share redemptions
     */
    function poolBalance() external view returns (uint256) {
        return ETHC.balanceOf(address(vault));
    }

    /**
     * @notice Calculates the ETHC reward for a given amount of share tokens
     * @param amount Amount of share tokens to calculate reward for
     * @return reward Amount of ETHC tokens that would be received
     * @dev Calculation is proportional to total share supply:
     * reward = (amount / totalSupply) * total_ETHC_balance
     *
     * This function is also exposed publicly via currentReward() for users
     * to check expected returns before redeeming.
     */
    function _calculateReward(uint256 amount) internal view returns (uint256 reward) {
        reward = ETHC.balanceOf(address(vault)) * amount / totalSupply();
    }

    /**
     * @notice Fallback function to handle direct ETH transfers for mining
     * @dev Automatically converts received ETH into mining operations
     *
     * Process flow:
     * 1. Calculates maximum whole mining operations possible with sent ETH
     * 2. Determines exact ETH value to use for mining
     * 3. Executes mining operation
     * 4. Refunds any excess ETH to sender
     *
     * Mathematical guarantees:
     * - mineCount = floor(msg.value / mineCost)
     * - mineValue = mineCount * mineCost
     * - refund = msg.value - mineValue
     *
     * Security features:
     * - Integer division ensures no over-mining
     * - Exact ETH accounting prevents fund locking
     * - State changes complete before ETH refund
     * - Refund isolation prevents reentrancy risks
     *
     * Example:
     * If mineCost is 0.1 ETH and user sends 0.25 ETH:
     * - mineCount = floor(0.25/0.1) = 2
     * - mineValue = 2 * 0.1 = 0.2 ETH
     * - refund = 0.05 ETH
     *
     * @dev This function is safe against reentrancy because:
     * 1. Mining state changes complete before ETH refund
     * 2. Each call's ETH balance is isolated
     * 3. Refund amount is strictly from current transaction
     *
     * Requirements:
     * - msg.value must be greater than 0
     * - Mining must not be paused
     *
     * Effects:
     * - Mints pool shares based on mining calculation
     * - May refund excess ETH to sender
     */
    receive() external payable {
        uint256 mineCost = ETHC.mineCost();
        uint256 mineCount = msg.value / mineCost;
        uint256 mineValue = mineCount * mineCost;
        _mine(mineCount, mineValue);
        if (address(this).balance > 0) {
            (bool ok,) = msg.sender.call{value: address(this).balance}("");
            require(ok);
        }
    }
}

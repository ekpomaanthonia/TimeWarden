# TimeWarden 🕰️

A smart contract for time-locked token deposits on the Stacks blockchain. TimeWarden allows users to lock their STX tokens for specified periods, creating a trustless escrow system with built-in time-based release mechanisms.

## Features

- **Secure Time-Locking**: Lock STX tokens for custom durations using block height
- **Multiple Vaults**: Users can create and manage multiple timelock vaults
- **Flexible Duration**: Set any lock duration in blocks (approximately 10 minutes per block)
- **Extend Locks**: Optionally extend lock durations before unlock time
- **Transparent Tracking**: View vault status, remaining time, and contract statistics
- **Emergency Controls**: Owner-only administrative functions

## How It Works

TimeWarden uses Stacks block height as a reliable time reference. When you create a vault:

1. Specify the amount of STX to lock and duration in blocks
2. Tokens are transferred to the contract and held securely
3. After the specified duration passes, you can withdraw your tokens
4. Vaults can be extended but not shortened once created

## Smart Contract Functions

### Public Functions

#### `create-vault(amount, lock-duration)`
Creates a new timelock vault with specified STX amount and duration in blocks.

**Parameters:**
- `amount` (uint): Amount of STX to lock (in microSTX)
- `lock-duration` (uint): Lock duration in blocks

**Returns:** Vault ID on success

#### `withdraw-from-vault(vault-id)`
Withdraws tokens from an unlocked vault.

**Parameters:**
- `vault-id` (uint): ID of the vault to withdraw from

**Returns:** Amount withdrawn on success

#### `extend-lock(vault-id, additional-duration)`
Extends the lock duration of an existing vault.

**Parameters:**
- `vault-id` (uint): ID of the vault to extend
- `additional-duration` (uint): Additional blocks to add to lock duration

### Read-Only Functions

#### `get-vault-info(vault-id)`
Returns complete information about a specific vault.

#### `get-user-vaults(user)`
Returns list of vault IDs owned by a user.

#### `is-vault-unlocked(vault-id)`
Checks if a vault is ready for withdrawal.

#### `get-time-until-unlock(vault-id)`
Returns remaining blocks until vault unlock.

#### `get-contract-stats()`
Returns contract statistics including total locked tokens and vault count.

## Usage Examples

### Creating a Vault
```clarity
;; Lock 1000 STX for 1000 blocks (~1 week)
(contract-call? .timewarden create-vault u1000000000 u1000)
```

### Checking Vault Status
```clarity
;; Get vault information
(contract-call? .timewarden get-vault-info u1)

;; Check if unlocked
(contract-call? .timewarden is-vault-unlocked u1)

;; Get remaining time
(contract-call? .timewarden get-time-until-unlock u1)
```

### Withdrawing Tokens
```clarity
;; Withdraw from vault ID 1
(contract-call? .timewarden withdraw-from-vault u1)
```

## Time Reference

TimeWarden uses Stacks block height for timing:
- **1 block ≈ 10 minutes** (average)
- **144 blocks ≈ 1 day**
- **1008 blocks ≈ 1 week**
- **4320 blocks ≈ 1 month**

## Error Codes

| Code | Description |
|------|-------------|
| u100 | Owner only operation |
| u101 | Vault not found |
| u102 | Already exists |
| u103 | Vault not yet unlocked |
| u104 | Insufficient balance |
| u105 | Invalid amount |
| u106 | Invalid unlock time |

## Security Considerations

- **Immutable Locks**: Once created, vault amounts and unlock times cannot be reduced
- **Owner Verification**: Only vault owners can withdraw or extend their locks
- **Block Height Timing**: Uses deterministic blockchain time, not wall clock time
- **No Emergency Withdrawals**: Tokens are locked until the specified time passes

## Deployment

1. Deploy the contract to Stacks testnet or mainnet
2. The deployer becomes the contract owner
3. Users can immediately start creating vaults

## Development

### Prerequisites
- Clarinet CLI for local development and testing
- Stacks wallet for deployment

### Testing
```bash
clarinet console
```

### Local Development
```bash
clarinet develop
```

## Use Cases

- **Savings Discipline**: Lock tokens to prevent impulsive spending
- **Vesting Schedules**: Create multiple vaults with staggered unlock times
- **DeFi Integration**: Use as a building block for more complex protocols
- **Goal-Based Saving**: Lock funds until specific future block heights

## Contributing

Contributions are welcome! Please ensure all changes include appropriate tests and documentation.

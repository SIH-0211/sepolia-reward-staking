# 스테이킹 스마트 컨트랙트 실습

## 1. 개요 (Overview)
이 저장소는 스테이킹 기능을 구현한 `Staking.sol` 파일을 포함하고 있습니다. 주요 구성 요소는 다음과 같습니다:
* **`ERC20Mock`**: 스테이킹 토큰과 보상 토큰을 생성하기 위해 무제한 발행(Minting)을 허용하는 테스트용 ERC-20 토큰 컨트랙트입니다.
* **`Staking`**: 사용자가 안전하게 토큰을 예치하고, 5분의 의무 예치 기간(Lock-up)을 가지며, 시간에 비례하여 보상을 얻고 출금할 수 있는 핵심 스테이킹 컨트랙트입니다. 비상 출금(Emergency Withdraw) 기능이 포함되어 있습니다.

## 2. Remix 배포 가이드 (Sepolia 테스트넷)

### 1단계: Remix 환경 준비
1. [Remix IDE](https://remix.ethereum.org/)에 접속합니다.
2. `Staking.sol`이라는 새 파일을 생성하고, 이 저장소에 있는 `Staking.sol` 코드를 복사하여 붙여넣습니다.
3. 컨트랙트를 컴파일합니다:
   - 좌측의 **Solidity Compiler** 탭으로 이동합니다.
   - 컴파일러 버전을 `0.8.20` 또는 그 이상으로 설정합니다.
   - **Compile Staking.sol** 버튼을 클릭합니다.

### 2단계: 토큰 배포하기 (Deploying the Tokens)
1. 좌측의 **Deploy & Run Transactions** 탭으로 이동합니다.
2. **Environment** 드롭다운에서 **Browser Extension**을 선택하여 **MetaMask**와 연결하고, 지갑이 반드시 **Sepolia 테스트 네트워크**에 연결되어 있는지 확인합니다.
3. **스테이킹 토큰 배포**:
   - "Deploy" 드롭다운 메뉴에서 `ERC20Mock`을 선택합니다.
   - `Deploy` 버튼 옆의 화살표를 눌러 매개변수를 입력합니다. (예: Name: `StakingToken`, Symbol: `STK`)
   - **Deploy** 버튼을 누르고 메타마스크에서 승인합니다. 
   - *배포된 STK 토큰의 컨트랙트 주소를 따로 메모해 둡니다.*
4. **보상 토큰 배포**:
   - 드롭다운에서 계속 `ERC20Mock`을 선택한 상태를 유지합니다.
   - 매개변수에 다른 이름과 심볼을 입력합니다. (예: Name: `RewardToken`, Symbol: `RWD`)
   - **Deploy** 버튼을 누르고 메타마스크에서 승인합니다.
   - *배포된 RWD 토큰의 컨트랙트 주소를 따로 메모해 둡니다.*

### 3단계: 스테이킹 컨트랙트 배포하기
1. "Deploy" 드롭다운에서 `Staking`을 선택합니다.
2. `Deploy` 버튼 옆의 화살표를 눌러 매개변수를 펼칩니다.
3. 2단계에서 배포한 토큰들의 주소를 입력합니다:
   - `_stakingToken`: 배포한 `STK` 토큰의 주소
   - `_rewardToken`: 배포한 `RWD` 토큰의 주소
4. **Transact**를 클릭하고 메타마스크에서 승인합니다.
   - *배포된 Staking 컨트랙트의 주소를 따로 메모해 둡니다.*

### 4단계: 초기 자금 셋업 및 충전
사용자에게 보상을 지급하려면 스테이킹 컨트랙트 내부에 보상 토큰이 있어야 하며, 사용자가 스테이킹을 하려면 지갑에 스테이킹 토큰이 있어야 합니다.
1. **스테이킹 컨트랙트에 보상(Rewards) 충전하기**:
   - 하단 'Deployed Contracts' 목록에서 **Reward Token (RWD)** 컨트랙트를 엽니다.
   - `mint` 함수에 다음 값을 입력하여 실행합니다:
     - `to`: **Staking 컨트랙트의 주소**
     - `amount`: `10000000000000000000000` (10,000 토큰, Wei 단위)
   - **Deploy**를 누르고 승인합니다.
2. **내 지갑에 스테이킹 토큰(STK) 충전하기**:
   - 하단 'Deployed Contracts' 목록에서 **Staking Token (STK)** 컨트랙트를 엽니다.
   - `mint` 함수에 다음 값을 입력하여 실행합니다:
     - `to`: **본인의 메타마스크 지갑 주소**
     - `amount`: `50000000000000000000` (50 토큰, Wei 단위)
   - **Deploy**를 누르고 승인합니다.

### 5단계: 사용 승인(Approve) 실행하기
스테이킹 컨트랙트가 `stake()` 함수를 통해 내 지갑의 토큰을 가져가려면(pull), 사전에 권한을 부여해야 합니다.
1. **Staking Token (STK)** 컨트랙트 내에서 `approve` 함수를 찾습니다.
2. 다음 값을 입력하여 `approve`를 실행합니다:
   - `spender`: **Staking 컨트랙트의 주소**
   - `value`: `50000000000000000000` (이동을 허락할 50 토큰)
3. **Deploy**를 누르고 승인합니다.

### 6단계: 스테이킹 및 출금 실행 (Staking & Unstaking)
1. **토큰 예치 (Stake)**:
   - 배포된 **Staking Contract**를 엽니다.
   - `stake` 함수에 `1000000000000000000` (1 토큰)을 입력하고 실행(Transact)합니다. 이제 보상이 쌓이기 시작합니다!
   - (선택) `stakedBalanceOf` 함수를 통해 예치된 1 토큰 잔액을 확인해 봅니다.
2. **보상 청구 (Claim Rewards)**:
   - 시간이 1~2분 정도 지날 때까지 기다립니다.
   - `claimReward` 함수를 실행합니다.
   - 메타마스크 승인 후, 터미널 로그의 `Reward Claimed` 이벤트를 확인하여 보상이 얼마나 지급되었는지 확인합니다.
3. **비상 출금 / 정상 출금 (Emergency Withdraw / Unstake)**:
   - 의무 예치 시간(5분)이 지나기 전에 `unstake` 함수에 `1000000000000000000`을 입력하고 호출해 봅니다. 트랜잭션이 실패(revert)하는 것이 정상입니다.
   - **방법 A:** 5분이 모두 경과할 때까지 기다린 후, `unstake()` 함수를 호출하여 정상적으로 출금합니다.
   - **방법 B:** 즉시 `emergencyWithdraw()` 함수를 호출하여 강제로 예치금을 회수합니다. 단, 이 경우 미수령 보상금은 모두 소멸됩니다.

---

## 3. 과제 진행 로그 (Assignment Log)

### 컨트랙트 배포 내역 (Contract Deployments - Sepolia)
   - csv 폴더에 Etherscan에서 확인한 트랜잭션 내역을 Deployed contract 단위로 csv 파일로 저장합니다.
   - 과제 검증 과정에서 발생한 트랜잭션 내역은 아래와 같습니다.
| 종류 | 컨트랙트 주소 (Contract Address) |
| :--- | :--- |
| **Staking Token (STK)** | `0xe46fc95d9E16d5D08e9a05d828E1D4026Af780b5` |
| **Reward Token (RWD)** | `0x3AE8fcc801E7C5255e65616fe001baF2A0673db7` |
| **Staking Contract** | `0x742fEA2D8b2837e20208a1A28e7aF352c6DdfFe9` |
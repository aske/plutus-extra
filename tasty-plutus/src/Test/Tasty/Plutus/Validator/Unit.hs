module Test.Tasty.Plutus.Validator.Unit (
  -- * Types
  InputType (..),
  OutputType (..),
  Input (..),
  Output (..),
  ContextBuilder,

  -- * Functions

  -- ** Basic construction
  input,
  output,
  signedWith,
  tag,

  -- ** Paying
  paysToPubKey,
  paysToWallet,
  paysSelf,
  paysOther,

  -- ** Spending
  spendsFromPubKey,
  spendsFromWallet,
  spendsFromPubKeySigned,
  spendsFromWalletSigned,
  spendsFromSelf,
  spendsFromOther,
) where

import Data.Kind (Type)
import Data.Sequence (Seq)
import Data.Sequence qualified as Seq
import Ledger.Crypto (PubKeyHash, pubKeyHash)
import Ledger.Scripts (ValidatorHash)
import Ledger.Value (Value)
import PlutusTx.Builtins (BuiltinData)
import PlutusTx.IsData.Class (ToData (toBuiltinData))
import Wallet.Emulator.Types (Wallet, walletPubKey)

-- | @since 1.0
data InputType
  = -- | @since 1.0
    PubKeyInput PubKeyHash
  | -- | @since 1.0
    ScriptInput ValidatorHash BuiltinData
  | -- | @since 1.0
    OwnInput BuiltinData BuiltinData
  deriving stock
    ( -- | @since 1.0
      Show
    )

-- | @since 1.0
data OutputType
  = -- | @since 1.0
    PubKeyOutput PubKeyHash
  | -- | @since 1.0
    ScriptOutput ValidatorHash BuiltinData
  | -- | @since 1.0
    OwnOutput BuiltinData
  deriving stock
    ( -- | @since 1.0
      Show
    )

-- | @since 1.0
data Input
  = -- | @since 1.0
    Input InputType Value
  deriving stock
    ( -- | @since 1.0
      Show
    )

-- | @since 1.0
data Output
  = -- | @since 1.0
    Output OutputType Value
  deriving stock
    ( -- | @since 1.0
      Show
    )

-- | @since 1.0
newtype ContextBuilder
  = ContextBuilder (Seq Input, Seq Output, Seq PubKeyHash, Seq BuiltinData)
  deriving stock
    ( -- | @since 1.0
      Show
    )
  deriving
    ( -- | @since 1.0
      Semigroup
    , -- | @since 1.0
      Monoid
    )
    via (Seq Input, Seq Output, Seq PubKeyHash, Seq BuiltinData)

-- | @since 1.0
input :: Input -> ContextBuilder
input x = ContextBuilder (Seq.singleton x, mempty, mempty, mempty)

-- | @since 1.0
output :: Output -> ContextBuilder
output x = ContextBuilder (mempty, Seq.singleton x, mempty, mempty)

-- | @since 1.0
signedWith :: PubKeyHash -> ContextBuilder
signedWith pkh = ContextBuilder (mempty, mempty, Seq.singleton pkh, mempty)

-- | @since 1.0
tag :: BuiltinData -> ContextBuilder
tag t = ContextBuilder (mempty, mempty, mempty, Seq.singleton t)

-- | @since 1.0
paysToPubKey :: PubKeyHash -> Value -> ContextBuilder
paysToPubKey pkh = output . Output (PubKeyOutput pkh)

-- | @since 1.0
paysToWallet :: Wallet -> Value -> ContextBuilder
paysToWallet wallet = paysToPubKey (walletPubKeyHash wallet)

-- | @since 1.0
paysSelf ::
  forall (a :: Type).
  (ToData a) =>
  Value ->
  a ->
  ContextBuilder
paysSelf v dt = output . Output (OwnOutput . toBuiltinData $ dt) $ v

-- | @since 1.0
paysOther ::
  forall (a :: Type).
  (ToData a) =>
  ValidatorHash ->
  Value ->
  a ->
  ContextBuilder
paysOther hash v dt =
  output . Output (ScriptOutput hash . toBuiltinData $ dt) $ v

-- | @since 1.0
spendsFromPubKey :: PubKeyHash -> Value -> ContextBuilder
spendsFromPubKey pkh = input . Input (PubKeyInput pkh)

-- | @since 1.0
spendsFromPubKeySigned :: PubKeyHash -> Value -> ContextBuilder
spendsFromPubKeySigned pkh v = spendsFromPubKey pkh v <> signedWith pkh

-- | @since 1.0
spendsFromWallet :: Wallet -> Value -> ContextBuilder
spendsFromWallet wallet = spendsFromPubKey (walletPubKeyHash wallet)

-- | @since 1.0
spendsFromWalletSigned :: Wallet -> Value -> ContextBuilder
spendsFromWalletSigned wallet = spendsFromPubKeySigned (walletPubKeyHash wallet)

-- | @since 1.0
spendsFromSelf ::
  forall (datum :: Type) (redeemer :: Type).
  (ToData datum, ToData redeemer) =>
  Value ->
  datum ->
  redeemer ->
  ContextBuilder
spendsFromSelf v d r =
  input . Input (OwnInput (toBuiltinData d) . toBuiltinData $ r) $ v

-- | @since 1.0
spendsFromOther ::
  forall (datum :: Type).
  (ToData datum) =>
  ValidatorHash ->
  Value ->
  datum ->
  ContextBuilder
spendsFromOther hash v d =
  input . Input (ScriptInput hash . toBuiltinData $ d) $ v

-- Helpers

walletPubKeyHash :: Wallet -> PubKeyHash
walletPubKeyHash = pubKeyHash . walletPubKey
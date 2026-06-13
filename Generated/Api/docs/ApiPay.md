# ApiPay

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**currency** | **String** |  | 
**id** | **UUID** | uuid v7 | 
**jws** | **String** | Signed transaction JWS from StoreKit; the input to Apple verification. | 
**loaded** | **Bool** |  | 
**orderId** | **String** | Google&#39;s per-purchase &#x60;orderId&#x60;, returned by the Play Developer API (not the client). Not used for dedup — &#x60;ref_id&#x60; is — because promo-code purchases may have no &#x60;orderId&#x60;. | [optional] 
**packageName** | **String** |  | 
**price** | **Int64** |  | 
**productId** | **String** |  | 
**provider** | [**ApiPayProvider**](ApiPayProvider.md) | Selects the verification path: Apple App Store vs Google Play. | 
**refId** | **String** | Globally-unique purchase id, used as the idempotency key for both stores. Apple: the &#x60;transactionId&#x60;, extracted server-side from the verified JWS   (empty on the incoming request — the server fills it in). Google: the &#x60;purchaseToken&#x60;, sent by the client. It is both the input to   Play Developer API verification and the idempotency key. | 
**userId** | **String** |  | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)



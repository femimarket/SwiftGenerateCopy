# PayRouteAPI

All URIs are relative to *https://api.earnfemi.com*

Method | HTTP request | Description
------------- | ------------- | -------------
[**pay**](PayRouteAPI.md#pay) | **POST** /pay | 


# **pay**
```swift
    open class func pay(id: UUID, provider: PayProvider, userId: String, credit: Int64? = nil, currency: String? = nil, jws: String? = nil, loaded: Bool? = nil, orderId: String? = nil, packageName: String? = nil, price: Int64? = nil, productId: String? = nil, refId: String? = nil, status: PayStatus? = nil, completion: @escaping (_ data: Pay?, _ error: Error?) -> Void)
```



### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import Api

let id = 987 // UUID | uuid v7
let provider = PayProvider() // PayProvider | Selects the verification path: Apple App Store vs Google Play.
let userId = "userId_example" // String | 
let credit = 987 // Int64 |  (optional)
let currency = "currency_example" // String |  (optional)
let jws = "jws_example" // String | Signed transaction JWS from StoreKit; the input to Apple verification. (optional)
let loaded = true // Bool |  (optional)
let orderId = "orderId_example" // String | Google's per-purchase `orderId`, returned by the Play Developer API (not the client). Not used for dedup — `ref_id` is — because promo-code purchases may have no `orderId`. (optional)
let packageName = "packageName_example" // String |  (optional)
let price = 987 // Int64 |  (optional)
let productId = "productId_example" // String |  (optional)
let refId = "refId_example" // String | Globally-unique purchase id, used as the idempotency key for both stores. Apple: the `transactionId`, extracted server-side from the verified JWS   (empty on the incoming request — the server fills it in). Google: the `purchaseToken`, sent by the client. It is both the input to   Play Developer API verification and the idempotency key. (optional)
let status = PayStatus() // PayStatus |  (optional)

PayRouteAPI.pay(id: id, provider: provider, userId: userId, credit: credit, currency: currency, jws: jws, loaded: loaded, orderId: orderId, packageName: packageName, price: price, productId: productId, refId: refId, status: status) { (response, error) in
    guard error == nil else {
        print(error)
        return
    }

    if (response) {
        dump(response)
    }
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **UUID** | uuid v7 | 
 **provider** | [**PayProvider**](PayProvider.md) | Selects the verification path: Apple App Store vs Google Play. | 
 **userId** | **String** |  | 
 **credit** | **Int64** |  | [optional] 
 **currency** | **String** |  | [optional] 
 **jws** | **String** | Signed transaction JWS from StoreKit; the input to Apple verification. | [optional] 
 **loaded** | **Bool** |  | [optional] 
 **orderId** | **String** | Google&#39;s per-purchase &#x60;orderId&#x60;, returned by the Play Developer API (not the client). Not used for dedup — &#x60;ref_id&#x60; is — because promo-code purchases may have no &#x60;orderId&#x60;. | [optional] 
 **packageName** | **String** |  | [optional] 
 **price** | **Int64** |  | [optional] 
 **productId** | **String** |  | [optional] 
 **refId** | **String** | Globally-unique purchase id, used as the idempotency key for both stores. Apple: the &#x60;transactionId&#x60;, extracted server-side from the verified JWS   (empty on the incoming request — the server fills it in). Google: the &#x60;purchaseToken&#x60;, sent by the client. It is both the input to   Play Developer API verification and the idempotency key. | [optional] 
 **status** | [**PayStatus**](PayStatus.md) |  | [optional] 

### Return type

[**Pay**](Pay.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json, text/plain

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)


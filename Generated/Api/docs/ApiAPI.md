# ApiAPI

All URIs are relative to *https://api.earnfemi.com*

Method | HTTP request | Description
------------- | ------------- | -------------
[**api**](ApiAPI.md#api) | **POST** /api | 
[**mediaGate**](ApiAPI.md#mediagate) | **GET** /{file} | Auth + per-GB debit gate in front of the &#x60;_upload&#x60; ServeDir on femi.market.   - not a media file → pass through (static site, app data, 404), free   - media file that isn&#39;t a real file in &#x60;_upload&#x60; → pass through, free   - media file in &#x60;_upload&#x60; → require Bearer, charge &#x60;size × pricing.gb&#x60;,     record a debit in the astc ledger, then let ServeDir stream the bytes. The gate only authorizes/charges; ServeDir still does the actual file streaming (range requests, mime, etc.).


# **api**
```swift
    open class func api(action: ApiAction, audio: String, balance: Int64, credit: Int64, file: String, id: UUID, image: String, messages: [ApiChatMessage], model: ApiAiModel, pay: ApiPay, pricing: ApiPricing, prompt: String, requestId: String, status: ApiStatus, userId: String, completion: @escaping (_ data: API?, _ error: Error?) -> Void)
```



### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import Api

let action = ApiAction() // ApiAction | 
let audio = "audio_example" // String | filename of already uploaded audio else default
let balance = 987 // Int64 | 
let credit = 987 // Int64 | 
let file = "file_example" // String | filename of result to retrieve
let id = 987 // UUID | uuid v7
let image = "image_example" // String | filename of already uploaded image else default
let messages = [ApiChatMessage(content: "content_example", role: ApiChatRole())] // [ApiChatMessage] | default value is non-empty array
let model = ApiAiModel() // ApiAiModel | 
let pay = ApiPay(currency: "currency_example", id: 123, jws: "jws_example", loaded: false, orderId: "orderId_example", packageName: "packageName_example", price: 123, productId: "productId_example", provider: ApiPayProvider(), refId: "refId_example", userId: "userId_example") // ApiPay | 
let pricing = ApiPricing(artist: 123, audio: 123, chat: 123, creator: 123, director: 123, falFlux2Pro: 123, falNanoBanana2: 123, falZImageTurbo: 123, gb: 123, generate: 123, id: 123, image: 123, lyricSync: 123, microPixLyra: 123, microPixVega: 123, nanoPixLuna: 123, nanoRenSpica: 123, question: 123, summary: 123, upload: 123) // ApiPricing | 
let prompt = "prompt_example" // String | 
let requestId = "requestId_example" // String | transient, managed by server
let status = ApiStatus() // ApiStatus | 
let userId = "userId_example" // String | 

ApiAPI.api(action: action, audio: audio, balance: balance, credit: credit, file: file, id: id, image: image, messages: messages, model: model, pay: pay, pricing: pricing, prompt: prompt, requestId: requestId, status: status, userId: userId) { (response, error) in
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
 **action** | [**ApiAction**](ApiAction.md) |  | 
 **audio** | **String** | filename of already uploaded audio else default | 
 **balance** | **Int64** |  | 
 **credit** | **Int64** |  | 
 **file** | **String** | filename of result to retrieve | 
 **id** | **UUID** | uuid v7 | 
 **image** | **String** | filename of already uploaded image else default | 
 **messages** | [**[ApiChatMessage]**](ApiChatMessage.md) | default value is non-empty array | 
 **model** | [**ApiAiModel**](ApiAiModel.md) |  | 
 **pay** | [**ApiPay**](ApiPay.md) |  | 
 **pricing** | [**ApiPricing**](ApiPricing.md) |  | 
 **prompt** | **String** |  | 
 **requestId** | **String** | transient, managed by server | 
 **status** | [**ApiStatus**](ApiStatus.md) |  | 
 **userId** | **String** |  | 

### Return type

[**API**](API.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json, text/plain

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **mediaGate**
```swift
    open class func mediaGate(file: String, completion: @escaping (_ data: [Int]?, _ error: Error?) -> Void)
```

Auth + per-GB debit gate in front of the `_upload` ServeDir on femi.market.   - not a media file → pass through (static site, app data, 404), free   - media file that isn't a real file in `_upload` → pass through, free   - media file in `_upload` → require Bearer, charge `size × pricing.gb`,     record a debit in the astc ledger, then let ServeDir stream the bytes. The gate only authorizes/charges; ServeDir still does the actual file streaming (range requests, mime, etc.).

`#[utoipa::path]` here is doc-only — the fn runs as `from_fn` middleware, not a route handler, but the attribute still emits the spec entry so the generated clients get a typed `downloadMedia(file)`. `servers(...)` pins it to femi.market (the global server is api.earnfemi.com); `Request`/`Next` args aren't documentable extractors so utoipa ignores them and uses the explicit `params`.

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import Api

let file = "file_example" // String | media filename in _upload

// Auth + per-GB debit gate in front of the `_upload` ServeDir on femi.market.   - not a media file → pass through (static site, app data, 404), free   - media file that isn't a real file in `_upload` → pass through, free   - media file in `_upload` → require Bearer, charge `size × pricing.gb`,     record a debit in the astc ledger, then let ServeDir stream the bytes. The gate only authorizes/charges; ServeDir still does the actual file streaming (range requests, mime, etc.).
ApiAPI.mediaGate(file: file) { (response, error) in
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
 **file** | **String** | media filename in _upload | 

### Return type

**[Int]**

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/octet-stream, text/plain

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)


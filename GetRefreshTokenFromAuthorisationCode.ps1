$config = @{  
    TokenUrl =  "https://identityservice.nmbrs.com/connect/token"
    Tokenhost =  "identityservice.nmbrs.com"          
    AuthorizeUrl =  "https://identityservice.nmbrs.com/connect/authorize"
    State =  "b6267d70-83ce-4515-a1cb-4006915fc8d4"
    RedirectUri =  "http://localhost:8080"  
    Client_secret =  '<YOUR_CLIENT_SECRET>'
    Client_id =  '<YOUR_CLIENT_ID>' 
    ResultRefreshTokenFile = "D:\\refresh_token_tmp.json"
}

$BrowserUri    = "$($config.AuthorizeUrl)?client_id=$($config.Client_id)&state=$($config.State)&scope=offline_access company.info.read employee.info.read employee.employment.read employee.payment.read debtor.info.read employee.orgstructure.read&response_type=code&redirect_uri=$($config.RedirectUri)"    

#open this uri in een webbrowser 
# it will open an consent page in NMBRS. After consent you will be redirected to the redirect URI you specified.
# This will result in an "not found" error, as the redirect Uri is not a valid endpoint, but the browser will display the authorization code in the address bar
#and you  can copy it from there, and paste it in the variable below.
# note that the authorization code is only valid for a short period of time and can only be used once.

$AuthorizationCode = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX-X"

$authenticationstring = [System.Web.HttpUtility]::UrlEncode($($config.Client_id)) + ":" + [System.Web.HttpUtility]::UrlEncode($($config.Client_secret))
$authorization = "Basic " + [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($authenticationstring))     
  
$splatParams = @{
    Uri     = "$($config.TokenUrl)"
    Method  = 'POST'
   
    Headers = @{
        'Content-Type'  = "application/x-www-form-urlencoded"
        'Authorization' = $authorization
        'Host' = "identityservice.nmbrs.com"
    }
    Body = "grant_type=authorization_code&code=$AuthorizationCode&redirect_uri=$($config.RedirectUri)"
}
try {
    $response = Invoke-RestMethod @splatParams  -UseBasicParsing      
    $response.refresh_token| out-File $config.ResultRefreshTokenFile
}
catch {
    $ex = $PSItem
    Write-Error "An error occurred while retrieving the refresh token: $($ex.Exception.Message)"   
}
# Copy the refresh token from the response and paste it in the configuration in helloid. 

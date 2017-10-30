local molpay = require "molpay.mobile.xdk.corona"
local widget = require( "widget" )

--library.init( listener )

local function callback( event )
native.showAlert( "MOLPay Results", event.results ,{ "OK" } )


    local options = 
{
    text = event.results,     
    x = 160,
    y = 120,
    width = 240,
    font = native.systemFont,   
    fontSize = 12,
    -- align = "right"  -- Alignment parameter
}
 
resultText = display.newText( options )
resultText:setFillColor( 0, 0, 0 )
end

local paymentDetails = 
{
    mp_amount = "1.1",
    mp_username = 'molpayapiusername',
    mp_password = 'molpayapipassword',
    mp_merchant_ID = 'molpaymerchant',
    mp_app_name = 'molpayappname',
    mp_verification_key = 'molpayverificationkey',
    mp_order_ID = "COR001", 
    mp_currency = "MYR",
    mp_country = "MY",
    mp_channel = "",
    mp_bill_description = "Corona payment test",
    mp_bill_name = "anyname",
    mp_bill_email = "email@email.com",
    mp_bill_mobile = "+647452",
    mp_sandbox_mode = true,
    mp_express_mode = false
};




local options = 
{
    text = "This app is for example xdk.",     
    x = 150,
    y = 10,
    width = 240,
    font = native.systemFont,   
    fontSize = 18,
    -- align = "right"  -- Alignment parameter
}
 
local myText = display.newText( options )
myText:setFillColor( 0, 0, 0 )
 



-- Function to handle button events
local function handleButtonEvent( event )
	if(event.phase == "ended") then
	 molpay.startMolpay( paymentDetails, callback)
	end
end




-- Create the widget
local button1 = widget.newButton(
    {
        left = 80,
        top = 200,
        id = "button1",
        label = "Start Pay",
        onEvent = handleButtonEvent,
        -- isVisible = false
    }
)
-- button1.isVisible = false;
display.setDefault( "background", 255, 255, 255 )


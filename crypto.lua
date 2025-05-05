local crypto = {}

local files = require("/lib/YL/files")

local function strToNums(s)
	local nums = {}
	for i = 1, #s do
	  table.insert(nums, string.byte(s, i))
	end
	return nums
end

local function numsToStr(nums)
	local chars = {}
	for i = 1, #nums do
		chars[i] = string.char(nums[i])
	end
	return table.concat(chars)
end

--[[
	modExp(base, exponent, modulus)
	returns (base ^ exponent % modulus)
]] 
function crypto.modExp(base, exponent, modulus)
	local out = 1; base = base % modulus
	while exponent > 0 do
		if exponent % 2 == 1 then out = (out * base) % modulus end
		base = (base * base) % modulus; exponent = math.floor(exponent / 2)
	end
	return out
end

--[[
	hash(message, modulus)
	returns a trivial hash of the message
]]
function crypto.hash(message, modulus)
	local out = 0xABCDEF
	for k = 1, #message do
		out = bit.bxor(out, string.byte(message, k) * 16777619)
		out = (out * 31) % modulus
	end
	return out
end

------------------------------------------------------------------------------
--[[                           KEY GENERATION                             ]]--
------------------------------------------------------------------------------

local primes = {101, 103, 107, 109, 113, 127, 131, 137}

local function randPrime()
  return primes[ math.random(1, #primes) ]
end

local function gcd(a, b)
  while b ~= 0 do a, b = b, a % b end
  return a
end

local function egcd(a, b)
  if b == 0 then return 1, 0 end
  local x1, y1 = egcd(b, a % b)
  return y1, x1 - math.floor(a/b)*y1
end

function crypto.generateKeys()
  local p, q = randPrime(), randPrime()
  while p == q do q = randPrime() end
  local modulus = p*q
  local phi = (p-1)*(q-1)
  local public_exponent = 65537
  if gcd(public_exponent, phi) ~= 1 then
    for c = 3, phi, 2 do
      if gcd(c, phi) == 1 then e = c break end
    end
  end
  local x, _ = egcd(public_exponent, phi)
  local private_exponent = (x % phi + phi) % phi
  return { modulus=modulus, public_exponent=public_exponent, private_exponent=private_exponent }
end

------------------------------------------------------------------------------
--[[                    ENCRYPTION  AND  SENDING                          ]]--
------------------------------------------------------------------------------

--[[
	encryptMessage(message, exponent, modulus)
	returns an encrypted message based on the public key of the target (exponent, modulus)
]]
function crypto.encryptMessage(message, exponent, modulus)
	local nums = strToNums(message)
	local ciphertext = {}
	for _, m in ipairs(nums) do
	  table.insert(ciphertext, crypto.modExp(m, exponent, modulus))
	end
	return ciphertext
end

--[[
	signRSA(msg, exponent, modulus)
	returns a signature based on the message, and private key
]]
function crypto.signRSA(message, exponent, modulus)
	local h = crypto.hash(message, modulus)
	local signature = crypto.modExp(h, exponent, modulus)
	return signature
end

--[[
	sendSecure(peerID, username, message)
	sends an encrypted message to the peerID PC on rednet,
	public key used is stored in "/rsa/others/"..username..".txt"
]]
function crypto.sendSecure(peerID, username, message)

	local self_rsa = files.readTable("rsa/self.txt")
	if not self_rsa then
		return false, "No rsa data for self"
	end
	local other_rsa = files.readTable("/rsa/others/"..username..".txt")
	if not other_rsa then
		return false, "No rsa data for "..username
	end

	local table_to_send = {
	  username = self_rsa.username,
	  message = message,
	  signature = crypto.signRSA(message, self_rsa.private_exponent, self_rsa.modulus)
	}

	local serialized = textutils.serialize(table_to_send)
	local ciphertext = crypto.encryptMessage(serialized, other_rsa.public_exponent, other_rsa.modulus)
	return rednet.send(peerID, ciphertext, "RSA")
end

------------------------------------------------------------------------------
--[[                    DECRYPTION  AND  RECEIVING                        ]]--
------------------------------------------------------------------------------


--[[
decryptMessage(crypt, exponent, modulus)
returns a plain, decryted version of crypt using exponent & modulus
as the private key
]]
function crypto.decryptMessage(crypt, exponent, modulus)
	local plainNums = {}
	for _, c in ipairs(crypt) do
		table.insert(plainNums, crypto.modExp(c, exponent, modulus))
	end
	return numsToStr(plainNums)
end
	
--[[
	verifyRSA(message, signature, exponent, modulus)
	verify if the signature was signed by the private key assiciated
	with the public key (exponent, modulus)
]]
function crypto.verifyRSA(message, signature, exponent, modulus)
	local h = crypto.hash(message, modulus)
	local h2 = crypto.modExp(signature, exponent, modulus)
	return h2 == h
end

--[[
	receiveSecure(timeout)
	waits timeout seconds for a rednet message, then decrypts it using
	info stored and checks the signature
]]
function crypto.receiveSecure(timeout)
	local self_rsa = files.readTable("rsa/self.txt")
	if not self_rsa then
		return nil, "No rsa data for self"
	end

	local id, ciphertext, proto = rednet.receive("RSA", timeout)
	if not id then
	  return nil, "No message received"
	end

	local message = crypto.decryptMessage(ciphertext, self_rsa.private_exponent, self_rsa.modulus)
	local received_table = textutils.unserialize(message)
	received_table.id = id
	
	local other_rsa = files.readTable("rsa/others/"..received_table.username..".txt")
	if not other_rsa then
		received_table.validSignature = false
		return received_table, "No rsa data for "..received_table.username
	end

	received_table.validSignature = crypto.verifyRSA(received_table.message, received_table.signature, other_rsa.public_exponent, other_rsa.modulus)
	return received_table
end

return crypto
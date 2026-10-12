// an ultra simple hlsl fragment shader
#pragma pack_matrix(row_major)

cbuffer CameraMatrices : register(b0)
{
    float4x4 viewMatrix;
    float4x4 projectionMatrix;
    float4 lightDirection;
    float4 lightColor;
    float4 cameraPosition;
}

// Use space1 to indicate descriptor set 1
Texture2D textures[] : register(t0, space1);
SamplerState samplers[] : register(s0, space1);

// Hard-coded material values as shown in the image
static float4 diffuse = { 1, 1, 1, 1 };
static float4 specular = { 1.0f, 1.0f, 1.0f, 1.0f };
static float4 ambient = { 0.75f, 0.75f, 0.75f, 1 };
static float4 emissive = { 0.1f, 0.1f, 0.1f, 1 };
static float Ns = 100;

struct PSInput
{
    float4 position : SV_POSITION;
    float3 normal : NORMAL;
    float2 texCoord : TEXCOORD0;
    float4 tangent : TANGENT;
    float3 worldPos : TEXCOORD1;
};

float3x3 CreateTBN(float3 normal, float4 tangent)
{
    // Normalize input vectors
    float3 N = normalize(normal);
    float3 T = normalize(tangent.xyz);
    
    // Re-orthogonalize tangent with respect to normal (Gram-Schmidt process)
    T = normalize(T - dot(T, N) * N);
    
    // Calculate bitangent using the tangent.w component to determine handedness
    float3 B = cross(N, T) * tangent.w;
    
    // Return the TBN matrix
    return float3x3(T, B, N);
}


float4 main(PSInput input) : SV_TARGET
{
    // Sample the base color from the first texture
    float4 baseColorTexture = textures[0].Sample(samplers[0], input.texCoord);
    
    // Sample the roughness from the second texture (green channel contains roughness)
    float roughness = textures[1].Sample(samplers[0], input.texCoord).g;
    
    // Sample the normal map (texture index 2) if it exists
    float3 normalMap = float3(0, 0, 1); // Default normal pointing up in tangent space
    if (textures[2].Sample(samplers[0], float2(0, 0)).a > 0) // Check if normal texture exists
    {
        // Sample normal map and convert from [0,1] to [-1,1] range
        normalMap = textures[2].Sample(samplers[0], input.texCoord).rgb * 2.0 - 1.0;
    }
    
    // Sample the emissive map (texture index 3) if it exists
    float3 emissiveColor = float3(0, 0, 0);
    if (textures[3].Sample(samplers[0], float2(0, 0)).a > 0) // Check if emissive texture exists
    {
        // Sample emissive map
        emissiveColor = textures[3].Sample(samplers[0], input.texCoord).rgb;
    }
    
    // Create TBN matrix to transform normal from tangent space to world space
    float3x3 TBN = CreateTBN(input.normal, input.tangent);
    
    // Transform normal from tangent space to world space
    float3 normal = normalize(mul(normalMap, TBN));
    
    // Calculate the light vector (opposite of light direction)
    float3 lightVector = -normalize(lightDirection.xyz);
    
    // Calculate the view vector (from point to camera)
    float3 viewVector = normalize(cameraPosition.xyz - input.worldPos);
    
    // Calculate the halfway vector for Blinn-Phong
    float3 halfwayVector = normalize(lightVector + viewVector);
    
    // Calculate the diffuse factor (Lambert's cosine law)
    float diffuseFactor = max(dot(normal, lightVector), 0.0);
    
    // Adjust specular power based on roughness (rougher = lower power)
    float adjustedNs = Ns * (1.0 - roughness * 0.9); // Scale to avoid going to zero
    
    // Calculate the specular factor with adjusted power
    float specularFactor = pow(max(dot(normal, halfwayVector), 0.0), adjustedNs);
    
    // Dampen specular intensity based on roughness (rougher = less specular)
    float specularIntensity = 1.0 - roughness;
    
    // Calculate the final color
    float3 ambientColor = ambient.xyz * baseColorTexture.rgb;
    float3 diffuseColor = diffuse.xyz * diffuseFactor * lightColor.xyz * baseColorTexture.rgb;
    float3 specularColor = specular.xyz * specularFactor * lightColor.xyz * specularIntensity;
    
    // Combine all lighting components including emissive from texture
    float3 finalColor = ambientColor + diffuseColor + specularColor + emissiveColor;
    
    return float4(finalColor, baseColorTexture.a);
}

struct VertexOutput
{
	/// Vertex world position
	float3 worldPosition : POSITION;

	float3 normal : NORMAL;

	float3 tangent : TANGENT;

	/// Shader view position
	float4 svPosition : SV_POSITION;

	/// Camera view position.
	float3 viewPosition : VIEW_POSITION;


	/// TBN (tangent, bitangent, normal) transformation matrix.
	float3x3 TBN : TBN;


	/// Vertex UV
	float2 uv : TEXCOORD;
};

//---------- Bindings ----------
struct Camera
{
	/// Camera transformation matrix.
	float4x4 view;

	/**
	*	Camera inverse view projection matrix.
	*	projection * inverseView.
	*/
	float4x4 invViewProj;
};
cbuffer CameraBuffer : register(b0)
{
	Camera camera;
};

struct Object
{
	/// Object transformation matrix.
	float4x4 transform;
};
cbuffer ObjectBuffer : register(b1)
{
	Object object;
};


static float4 cubeVertices[] =
{
	float4(-0.5f, -0.5f, -0.5f, 1.0f),
	float4(-0.5f, -0.5f, 0.5f, 1.0f),
	float4(-0.5f, 0.5f, -0.5f, 1.0f),
	float4(-0.5f, 0.5f, 0.5f, 1.0f),
	float4(0.5f, -0.5f, -0.5f, 1.0f),
	float4(0.5f, -0.5f, 0.5f, 1.0f),
	float4(0.5f, 0.5f, -0.5f, 1.0f),
	float4(0.5f, 0.5f, 0.5f, 1.0f),
};

static float3 cubeColors[] =
{
	float3(0.0f, 0.0f, 0.0f),
	float3(0.0f, 0.0f, 1.0f),
	float3(0.0f, 1.0f, 0.0f),
	float3(0.0f, 1.0f, 1.0f),
	float3(1.0f, 0.0f, 0.0f),
	float3(1.0f, 0.0f, 1.0f),
	float3(1.0f, 1.0f, 0.0f),
	float3(1.0f, 1.0f, 1.0f),
};

static uint3 cubeIndices[] =
{
	uint3(0, 2, 1),
	uint3(1, 2, 3),
	uint3(4, 5, 6),
	uint3(5, 7, 6),
	uint3(0, 1, 5),
	uint3(0, 5, 4),
	uint3(2, 6, 7),
	uint3(2, 7, 3),
	uint3(0, 4, 6),
	uint3(0, 6, 2),
	uint3(1, 3, 7),
	uint3(1, 7, 5),
};

[outputtopology("triangle")]
[numthreads(12, 1, 1)]
void main(in uint groupThreadId : SV_GroupThreadID,
	out vertices VertexOutput outVerts[8],
	out indices uint3 outIndices[12])
{
	const uint numVertices = 8;
	const uint numPrimitives = 12;

	SetMeshOutputCounts(numVertices, numPrimitives);

	if (groupThreadId < numVertices)
	{
		float4 pos = cubeVertices[groupThreadId];
		
		//---------- Position ----------
		const float4 worldPosition4 = mul(object.transform, pos);
		outVerts[groupThreadId].worldPosition = worldPosition4.xyz / worldPosition4.w;
		outVerts[groupThreadId].svPosition = mul(camera.invViewProj, worldPosition4);
		outVerts[groupThreadId].viewPosition = float3(camera.view._14, camera.view._24, camera.view._34);


		//---------- Normal ----------
		const float3 normal = normalize(mul((float3x3)object.transform, pos.xyz));
		const float3 tangent = normalize(mul((float3x3)object.transform, pos.xyz));
		const float3 bitangent = cross(normal, tangent);

		/// HLSL uses row-major constructor: transpose to get TBN matrix.
		outVerts[groupThreadId].TBN = transpose(float3x3(tangent, bitangent, normal));


		//---------- UV ----------
		outVerts[groupThreadId].uv = pos.xy;
	}

	outIndices[groupThreadId] = cubeIndices[groupThreadId];
}

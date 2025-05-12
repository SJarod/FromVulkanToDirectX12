
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

struct Meshlet
{
	uint32_t vertexCount;
	uint32_t vertexOffset;
	uint32_t primitiveCount;
	uint32_t primitiveOffset;
};
StructuredBuffer<Meshlet> meshlets: register(t5);
// vertex buffer
StructuredBuffer<float3> vertexBufferPositions: register(t6);
StructuredBuffer<float3> vertexBufferNormals: register(t9);
StructuredBuffer<float3> vertexBufferTangents: register(t10);
StructuredBuffer<float2> vertexBufferTexCoords: register(t11);
// index buffer
StructuredBuffer<uint16_t> vertexIndices: register(t7);
StructuredBuffer<uint> primitiveIndices: register(t8);

[outputtopology("triangle")]
[numthreads(128, 1, 1)]
void main(
	in uint groupId : SV_GroupID,
	in uint groupThreadId : SV_GroupThreadID,
	out vertices VertexOutput outVerts[128],
	out indices uint3 outIndices[128])
{
	Meshlet meshlet = meshlets[groupId];

	SetMeshOutputCounts(meshlet.vertexCount, meshlet.primitiveCount);

	if (groupThreadId < meshlet.vertexCount)
	{
		uint vertexIndex = vertexIndices[meshlet.vertexOffset + groupThreadId];
		float4 pos = float4(vertexBufferPositions[vertexIndex], 1.0f);
		
		//---------- Position ----------
		const float4 worldPosition4 = mul(pos, object.transform);
		outVerts[groupThreadId].worldPosition = worldPosition4.xyz / worldPosition4.w;
		outVerts[groupThreadId].svPosition = mul(worldPosition4, camera.invViewProj);
		outVerts[groupThreadId].viewPosition = float3(camera.view._14, camera.view._24, camera.view._34);


		//---------- Normal ----------
		const float3 normal = normalize(mul((float3x3)object.transform, vertexBufferNormals[vertexIndex]));
		const float3 tangent = normalize(mul((float3x3)object.transform, vertexBufferTangents[vertexIndex]));
		const float3 bitangent = cross(normal, tangent);
		outVerts[groupThreadId].normal = vertexBufferNormals[vertexIndex];
		outVerts[groupThreadId].tangent = tangent;

		// HLSL uses row-major constructor: transpose to get TBN matrix.
		outVerts[groupThreadId].TBN = transpose(float3x3(tangent, bitangent, normal));


		//---------- UV ----------
		outVerts[groupThreadId].uv = vertexBufferTexCoords[vertexIndex];
	}

	if (groupThreadId < meshlet.primitiveCount)
	{
		uint packedIndices = primitiveIndices[meshlet.primitiveOffset + groupThreadId];

		outIndices[groupThreadId] = uint3(packedIndices & 0x3FF,
			(packedIndices >> 10) & 0x3FF,
			(packedIndices >> 20) & 0x3FF);
	}
}

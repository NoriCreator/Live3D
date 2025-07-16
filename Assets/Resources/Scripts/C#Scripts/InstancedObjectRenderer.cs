// Unity用：Compute Shaderで位置情報生成、モーションはシェーダー側で制御（ペンライト用途）
using UnityEngine;

public class InstancedObjectRenderer : MonoBehaviour
{
    [Header("描画対象のメッシュとマテリアル")]
    public Mesh instanceMesh;
    public Material instanceMaterial;
    public ComputeShader computeShader;

    [Header("座席・配置データ")]
    public Audience audience = Audience.Default();

    private GraphicsBuffer matrixBuffer;
    private GraphicsBuffer basePositionBuffer;
    private Bounds drawBounds;

    private int kernelID;
    private uint threadGroupSizeX;

    void Start()
    {
        int instanceCount = audience.TotalSeatCount;

        // オブジェクトカリング範囲 中心(0, 0, 0) XYZ -500 ~ 500の立方体 のバウンディングボックスの定義
        drawBounds = new Bounds(Vector3.zero, Vector3.one * 1000f);

        // GPUに渡すバッファの定義　(構造体型データ格納, 描画するオブジェクトの複製数, 3D行列のfloat4x4サイズ)
        matrixBuffer = new GraphicsBuffer(GraphicsBuffer.Target.Structured, instanceCount, sizeof(float) * 16);

        // ベース位置バッファ（xyz: 位置、w: インスタンスID等の利用）
        basePositionBuffer = new GraphicsBuffer(GraphicsBuffer.Target.Structured, instanceCount, sizeof(float) * 4);

        Vector4[] basePositions = new Vector4[instanceCount];
        for (int i = 0; i < instanceCount; i++)
        {
            var (block, seat) = audience.GetCoordinatesFromIndex(i);
            var pos = audience.GetPositionOnPlane(block, seat);
            basePositions[i] = new Vector4(pos.x, 0f, pos.y, i); // w: インスタンスID
        }
        // バッファにinstanceCountの数だけ出力する座標を指定するデータを格納
        basePositionBuffer.SetData(basePositions);

        // Compute Shader 設定
        kernelID = computeShader.FindKernel("CSMain");

        // ComputeShaderで実行されるメイン関数のスレッド数　[numthreads(64, 1, 1)]　1は_で省略
        // threadGroupSizeXにCSMainのスレッドグループサイズのx成分を格納
        computeShader.GetKernelThreadGroupSizes(kernelID, out threadGroupSizeX, out _, out _);

        // CSMainにバッファとパラメータを接続
        computeShader.SetBuffer(kernelID, "Result", matrixBuffer);
        computeShader.SetBuffer(kernelID, "BasePosition", basePositionBuffer);
        computeShader.SetInt("instanceCount", instanceCount);
        computeShader.SetFloat("_SwingFrequency", audience.swingFrequency);
        computeShader.SetFloat("_SwingOffset", audience.swingOffset);
        computeShader.SetFloat("_SeatPitchX", audience.seatPitch.x);
        computeShader.SetFloat("_SeatPitchY", audience.seatPitch.y);

        // ComputeShader初回実行
        DispatchComputeShader(instanceCount);

        // マテリアルにバッファを設定
        instanceMaterial.SetBuffer("matrixBuffer", matrixBuffer);
        instanceMaterial.SetBuffer("basePositionBuffer", basePositionBuffer);
    }

    void DispatchComputeShader(int count)
    {
        computeShader.SetFloat("_Time", Time.time);

        // Compute Shaderのスレッドグループ数を計算
        int threadGroupsX = Mathf.CeilToInt(count / (float)threadGroupSizeX);

        computeShader.Dispatch(kernelID, threadGroupsX, 1, 1);
    }

    void Update()
    {
        DispatchComputeShader(audience.TotalSeatCount);

        // 毎フレーム位置は一定、モーションはシェーダー側で処理
        Graphics.DrawMeshInstancedProcedural(instanceMesh, 0, instanceMaterial, drawBounds, audience.TotalSeatCount);
    }

    void OnDestroy()
    {
        // バッファ解放
        matrixBuffer?.Release();
        basePositionBuffer?.Release();
    }
}

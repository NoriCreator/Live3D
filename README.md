# Live3D

## ファイル構成

### **Assets/Resources/Scripts - ソースコード**
- **C# Scripts**
  - **Audience.cs**
    ペンライトを出力する座標を管理します。

  - **InstancedObjectRenderer.cs**
    ペンライトのマトリックスを格納するための GraphicsBuffer を作成します。  
    Audience の情報をもとに各ペンライトの座標を設定し、GPU インスタンシングによる大量描画を行います。

- **Shaders**
  - **Amekoro_Shader.shader**
    ステージ中心で踊るキャラクターの Surface シェーダーです。

  - **ComputeInstancingWithMotion.compute**
    InstancedObjectRenderer.cs から GraphicsBuffer 経由でマトリックス情報を受け取り、  
    ペンライトの挙動を計算し、その結果を格納します。

  - **Monitor.shader**
    ステージに配置された巨大モニターを描画します。  
    実際のモニターのような点々の質感をマスクテクスチャで表現しています。

  - **PenLightMat.shader**
    InstancedObjectRenderer.cs から GraphicsBuffer 経由でマトリックス情報を受け取り、  
    頂点情報を設定します。インスタンス ID に応じて、ペンライトに波のような色変化を加えます。

---

### **BuildData**
3D ライブ演出に使用するビルド済みのデータです。  
`Live3D.exe` を実行することで体験可能です。

---

### **MMDを利用したLive3D制作の取り組み.pptx**
本プロジェクトにおける取り組みや技術的工夫をまとめたスライド資料です。  
ポートフォリオや発表資料として使用します。

---

## お問い合わせ

石川 紀元  
メール: itowokashi.nori@gmail.com
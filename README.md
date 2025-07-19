# Live3D

## ファイル構成

### **Assets/Resources/Scripts - ソースコード**
- **C#Script**
    Audience.cs
    - ペンライトを出力する座標を管理

    InstancedObjectRenderer.cs
    - ペンライトのマトリックスを格納するためのGraphic Bufferを作成
    - Audienceの情報をもとに各ペンライトの座標を設定
    - GPUインスタンシングでペンライトを大量描画の命令をします

- **Shader**
    Amekoro_Shader.shader
    - ステージ中心で踊るキャラクターのSurfaceシェーダーです

    ComputeInstancingWithMotion.compute
    - InstancedObjectRenderer.csからGraphic Bufferでマトリックス情報を受け取ります
    - マトリックス情報をもとに大量描画されるペンライトの挙動計算を行い、結果情報を格納

    Monitor.shader
    - ステージに配置された巨大モニターを描画します
    - リアルの巨大モニターのような点々をマスクテクスチャで表現しました

    PenLightMat.shader
    - InstancedObjectRenderer.csからGraphic Bufferでマトリックス情報を受け取ります
    - マトリックス情報をもとに頂点情報を設定
    - インスタンスIDからペンライトの色にウェーブを掛けます

### **BuildData**
- 3Dライブ演出に使用するビルド済みのデータを保存しています
- Live3D.exeで実行します

### **MMDを利用したLive3D制作の取り組み.pptx**  
- 本プロジェクトにおける取り組みや技術的工夫をまとめたスライド資料です
- ポートフォリオ・発表用に使用

---

# お問い合わせ
石川 紀元
メール: itowokashi.nori@gmail.com
# Weakly Supervised Semantic Segmentation by Pixel-to-Prototype Contrast

## Overview
The Pytorch implementation of Weakly Supervised Semantic Segmentation by Pixel-to-Prototype Contrast.

[[arXiv]](https://arxiv.org/abs/2110.07110)

>Though image-level weakly supervised semantic segmentation (WSSS) has achieved great progress with Class Activation Maps (CAMs) as the cornerstone, the large supervision gap between classification and segmentation still hampers the model to generate more complete and precise pseudo masks for segmentation. In this study, we propose weakly-supervised pixel-to-prototype contrast that can provide pixel-level supervisory signals to narrow the gap. Guided by two intuitive priors, our method is executed across different views and within per single view of an image, aiming to impose cross-view feature semantic consistency regularization and facilitate intra(inter)-class compactness(dispersion) of the feature space. Our method can be seamlessly incorporated into existing WSSS models without any changes to the base networks and does not incur any extra inference burden. Extensive experiments manifest that our method consistently improves two strong baselines by large margins, demonstrating the effectiveness.
<img width="801" alt="图片" src="https://user-images.githubusercontent.com/83934424/157233454-9a0fbae6-2e05-4285-9042-70af1449ad96.png">


## Prerequisites
- Python 3.6
- pytorch>=1.6.0
- torchvision
- CUDA>=9.0
- pydensecrf from https://github.com/lucasb-eyer/pydensecrf
- others (opencv-python etc.)


## Preparation

1. Clone this repository.
2. Data preparation.
   Download PASCAL VOC 2012 devkit follow instructions in http://host.robots.ox.ac.uk/pascal/VOC/voc2012/#devkit. It is suggested to make a soft link toward downloaded dataset. Then download the annotation of VOC 2012 trainaug set (containing 10582 images) from https://www.dropbox.com/s/oeu149j8qtbs1x0/SegmentationClassAug.zip?dl=0 and place them all as ```VOC2012/SegmentationClassAug/xxxxxx.png```. Download the image-level labels ```cls_label.npy``` from https://github.com/YudeWang/SEAM/tree/master/voc12/cls_label.npy
3. Download ImageNet pretrained backbones.
   We use ResNet-38 for initial seeds generation and ResNet-101 for segmentation training. Download pretrained ResNet-38 from https://drive.google.com/file/d/15F13LEL5aO45JU-j45PYjzv5KW5bn_Pn/view
 

## Model Zoo
   Download the pretrained model from ... and training results together with intermediate products from ...
   
|     | Model | val | +crf | test | +crf | Checkpoint | Link |
| --- | --- | --- | --- | --- | --- |--------------------------| --- |
| SEAM | contrast | 55.55 | 55.55 | 55.55 | 55.55 | [Download]()             | -   |
|     | affinitynet | 55.55 | 55.55 | 55.55 | 55.55 | [Download]()             | -   |
|     | deeplabv1 | 55.55 | 55.55 | 55.55 | 55.55 | [Download]()             | https:// |
| EPS | contrast | 55.55 | 55.55 | 55.55 | 55.55 | [Download]()             | -   |
|     | deeplabv1 | 55.55 | 55.55 | 55.55 | 55.55 | [Download]()             | http:// |
|     | deeplabv2 | 55.55 | 55.55 | 55.55 | 55.55 | [Download]()             | http:// |

   The generated initial seeds, pseudo masks for training can be downloaded [here]().

## Usage

### Step1: Initial Seed Generation with Contrastive Learning.
1. Contrast train.
   ```
   python contrast_train.py  \
     --weights $pretrained_model \
     --voc12_root VOC2012 \
     --session_name $your_session_name \
     --batch_size $bs
   ```

2. Contrast inference.

   Download the pretrained model from [...] or train from scratch, set ```--weight``` and then run:
   ```
   python contrast_infer.py \
     --weights $contrast_weight \ 
     --infer_list $[voc12/val.txt | voc12/train.txt | voc12/train_aug.txt] \
     --out_cam $your_cam_npy_dir \
     --out_cam_pred $your_cam_png_dir \
     --out_crf $your_crf_png_dir
   ```

3. Evaluation.

   Following SEAM, we recommend you to use ```--curve``` to select an optimial background threshold.
   ```
   python eval.py \
     --list VOC2012/ImageSets/Segmentation/$[val.txt | train.txt] \
     --predict_dir $your_result_dir \
     --gt_dir VOC2012/SegmentationClass \
     --comment $your_comments \
     --type $[npy | png] \
     --curve True
   ```

### Step2: Refine with AffinityNet.
1. Preparation.

   Prepare the files (```la_crf_dir``` and ```ha_crf_dir```) needed for training AffinityNet. You can also use our processed crf outputs with ```alpha=4/8``` from here.
   ```
   python aff_prepare.py \
     --voc12_root VOC2012 \
     --cam_dir $your_cam_npy_dir \
     --out_crf $your_crf_alpha_dir 
   ```

2. AffinityNet train.
   ```
   python aff_train.py \
     --weights $pretrained_model \
     --voc12_root VOC2012 \
     --la_crf_dir $your_crf_dir_4.0 \
     --ha_crf_dir $your_crf_dir_8.0 \
     --session_name $your_session_name
   ```

3. Random walk propagation & Evaluation.

   Use the trained AffinityNet to conduct RandomWalk for refining the CAMs from Step1. Trained model can be found in Model Zoo.
   ```
   python aff_infer.py \
     --weights $aff_weights \
     --voc12_root VOC2012 \
     --infer_list $[voc12/val.txt | voc12/train.txt] \
     --cam_dir $your_cam_dir \
     --out_rw $your_rw_dir
   ```

4. Pseudo mask generation. 
   Generate the pseudo masks for training the DeepLab Model. Dense CRF is used in this step.
   ```
   python aff_infer.py \
     --weights $aff_weights \
     --infer_list voc12/trainaug.txt \
     --cam_dir $your_cam_dir \
     --voc12_root VOC2012 \
     --out_rw $your_rw_dir
   ```


### Step3: Segmentation training with DeepLab
1. Training. 
   
   we use the segmentation repo from https://github.com/YudeWang/semantic-segmentation-codebase/tree/main/experiment/seamv1-pseudovoc. Training and inference codes are available in ```segmentation/experiment/```. Set ```DATA_PSEUDO_GT: $your_pseudo_label_path``` in ```config.py```. Then run:
   ```
   python train.py
   ```

2. Inference. 

   Check test configration in ```config.py``` (ckpt path) and val/test set selection in ```test.py```.  Then run:
   ```
   python test.py
   ```
   
   For test set evaluation, you need to download test set images and submit the segmentation results to the official voc server.
   
For integrating our approach into the [EPS](https://openaccess.thecvf.com/content/CVPR2021/papers/Lee_Railroad_Is_Not_a_Train_Saliency_As_Pseudo-Pixel_Supervision_for_CVPR_2021_paper.pdf) model, you can change branch to ```EPS``` via:
```angular2html
git checkout eps; cd wEPS 
```
Then conduct train or inference following instructions above. Trained models & processed files can be download in Model Zoo.

## Acknowledgements
We sincerely thank [Yude Wang](https://scholar.google.com/citations?user=5aGpONMAAAAJ&hl=en) for his great work SEAM in CVPR'20. We borrow codes heavly from his repositories [SEAM](https://github.com/YudeWang/SEAM) and [Segmentation](https://github.com/YudeWang/semantic-segmentation-codebase/tree/main/experiment/seamv1-pseudovoc).
We also thank [Seungho Lee](https://scholar.google.com/citations?hl=zh-CN&user=vUM0nAgAAAAJ) for his [EPS](https://openaccess.thecvf.com/content/CVPR2021/papers/Lee_Railroad_Is_Not_a_Train_Saliency_As_Pseudo-Pixel_Supervision_for_CVPR_2021_paper.pdf) and [jiwoon-ahn](https://github.com/jiwoon-ahn) for his [AffinityNet](https://github.com/jiwoon-ahn/psa) and [IRN](https://github.com/jiwoon-ahn/irn). Without them, we could not finish this work.

## Citation
```
@article{du2021weakly,
  title={Weakly Supervised Semantic Segmentation by Pixel-to-Prototype Contrast},
  author={Du, Ye and Fu, Zehua and Liu, Qingjie and Wang, Yunhong},
  journal={arXiv preprint arXiv:2110.07110},
  year={2021}
}
```
